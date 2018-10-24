@App.controller 'DashboardController', ($scope, $cookies, $sce, MnoeMarketplace, MnoErrorsHandler, MnoeCurrentUser, MnoeAdminConfig, UserRoles, STAFF_PAGE_AUTH) ->
  'ngInject'
  main = this

  main.errorHandler = MnoErrorsHandler
  main.staffPageAuthorized = STAFF_PAGE_AUTH
  main.adminConfig = MnoeAdminConfig
  main.showProductManagement =
    MnoeAdminConfig.areLocalProductsEnabled() ||
    MnoeAdminConfig.isProductMarkupEnabled() ||
    MnoeAdminConfig.areSettingsEnabled()
  main.showWebstore =
    MnoeAdminConfig.isStaffEnabled() ||
    MnoeAdminConfig.isSubTenantEnabled() ||
    MnoeAdminConfig.isFinanceEnabled() ||
    MnoeAdminConfig.isReviewingEnabled() ||
    MnoeAdminConfig.areQuestionsEnabled() ||
    MnoeAdminConfig.isDashboardTemplatesEnabled() ||
    MnoeAdminConfig.isAuditLogEnabled()
  main.isSupportRoleEnabled = MnoeAdminConfig.isSupportRoleEnabled()

  main.trustSrc = (src) ->
    $sce.trustAsResourceUrl(src)

  # Preload data to be reused in the app
  # Marketplace is cached
  # MnoeMarketplace.getApps()

  main.isLoading = true
  MnoeCurrentUser.getUser().then(
    # Display the layout
    (user) ->
      main.user = user
      main.organizationAvailable = user.organizations? && user.organizations.length > 0
      main.showSupportScreen = UserRoles.isSupportAgent(user)
      main.isLoading = false
  )

  main.currentSupportOrganization = ->
    main.user.support_org_id

  main.supportLoggedIn = (user) ->
    UserRoles.supportRoleLoggedIn(user)

  main.exit = ->
    MnoeCurrentUser.logout()

  main.refreshUser = ->
    MnoeCurrentUser.refreshUser().then((user) -> main.user = user)

  $scope.$on('refreshDashboardLayoutSupport', ->
    main.refreshUser()
  )

  return
