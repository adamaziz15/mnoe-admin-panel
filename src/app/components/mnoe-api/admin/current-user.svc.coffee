# Service to update the current user

# We're not using angular-devise as the update functionality hasn't been
# merged yet.
# As we're using Devise + Her, we have custom routes to update the current user
# It then makes more sense to have an extra service rather than have customised
# fork of the upstream library


@App.service 'MnoeCurrentUser', ($window, $state, $q, $timeout, $cookies, IntercomSvc, MnoeApiSvc, MnoeAdminConfig, UserRoles) ->
  _self = @

  # Store the current_user promise
  # Only one call will be executed even if there is multiple callers at the same time
  userPromise = null

  # Save the current user in variable to be able to reference it directly
  @user = {}

  # Get the current user profile
  @getUser = ->
    return userPromise if userPromise?
    userPromise = MnoeApiSvc.one('current_user').get().then(
      (response) ->
        angular.copy(response.data, _self.user)
        response.data
    )

  @skipIfNotAdmin = () ->
    @skipIfNotAdminRole(['admin'])

  @skipIfSupportAgent = () ->
    # Available roles except support
    roles = MnoeAdminConfig.adminRoles().map((roleHash) -> roleHash.value).filter((role) -> role isnt 'support')
    @skipIfNotAdminRole(roles)

  @skipIfNotAdminRole = (admin_roles) ->
    deferred = $q.defer()
    _self.getUser().then(=>
      if _self.user.admin_role? && _self.user.admin_role in admin_roles
        return deferred.resolve()
      else
        $timeout(=>
          # Runs after the authentication promise has been rejected.
          @redirectHome()
        )
        deferred.reject()
    )
    return deferred

  @redirectHome = () ->
    state = switch
      when UserRoles.isSupportAgent(_self.user) then 'dashboard.support'
      else 'dashboard.home'
    $state.go(state)

  @logout = ->
    # Shutdown the Intercom session
    IntercomSvc.logOut()
    _self.getUser().then(
      (response) ->
        # Redirect to dashboard if the user has at least one organization
        if response.organizations? && response.organizations.length > 0
          $window.location.assign("/dashboard/")
        # Logout if the user has no organization
        else
          $window.location.assign("/dashboard/#!/logout")
    )

  @refreshUser = ->
    userPromise = null
    _self.getUser().then(
      (user) ->
        _self.skipIfNotAdminRole(['admin', 'support'])
        user
    )

  return @
