class PaymentController extends KDController

  getGroup = ->
    KD.getSingleton('groupsController').getCurrentGroup()

  getBalance: (type, callback)->

    { JPaymentPlan } = KD.remote.api

    if type is 'user'
      JPaymentPlan.getUserBalance callback
    else
      JPaymentPlan.getGroupBalance callback

  fetchPaymentMethods: (callback) ->

    { dash } = Bongo

    methods       = null
    preferredPaymentMethod = null
    appStorage    = new AppStorage 'Account', '1.0'
    queue = [

      -> appStorage.fetchStorage (err) ->
        preferredPaymentMethod = appStorage.getValue 'preferredPaymentMethod'
        queue.fin err

      => KD.whoami().fetchPaymentMethods (err, paymentMethods) ->
        methods = paymentMethods
        queue.fin err
    ]

    dash queue, (err) -> callback err, {
      preferredPaymentMethod
      methods
      appStorage
    }

  observePaymentSave: (modal, callback) ->
    modal.on 'PaymentInfoSubmitted', (paymentMethodId, updatedPaymentInfo) =>
      @updatePaymentInfo paymentMethodId, updatedPaymentInfo, (err, savedPaymentInfo) =>
        return callback err  if err
        callback null, savedPaymentInfo
        @emit 'PaymentDataChanged'

  removePaymentMethod: (paymentMethodId, callback) ->
    { JPayment } = KD.remote.api
    JPayment.removePaymentMethod paymentMethodId, (err) =>
      return callback err  if err
      @emit 'PaymentDataChanged'

  fetchSubscription: do ->
    findActiveSubscription = (subs, planCode, callback) ->
      subs.reverse().forEach (sub) ->
        if sub.planCode is planCode and sub.status in ['canceled', 'active']
          return callback sub

      callback 'none'

    fetchSubscription = (type, planCode, callback) ->
      { JPaymentSubscription } = KD.remote.api

      if type is 'group'
        getGroup().checkPayment (err, subs) =>
          findActiveSubscription subs, planCode, callback
      else
        JPaymentSubscription.getUserSubscriptions (err, subs) ->
          findActiveSubscription subs, planCode, callback

  confirmPayment: ({ type, planCode, paymentMethodId }, callback = (->)) ->
    getGroup().canCreateVM { type, planCode, paymentMethodId }, (err, status) =>
      @fetchSubscription type, planCode, (subscription) =>
        cb = (needBilling, balance, amount) =>
          debugger
          # @createPaymentConfirmationModal {
          #   needBilling, balance, amount, type, group, plan, subscription
          # }, callback

        if status
          cb no, 0, 0
        else
          @fetchPaymentInfo type, group, (err, billing) =>
            needBilling = err or not billing?.cardNumber?

            @getBalance type, group, (err, balance) =>
              balance = 0  if err
              cb needBilling, balance, plan.feeMonthly

  makePayment: (type, plan, amount) ->
    vmController = KD.getSingleton('vmController')

    if amount is 0
      vmController.createGroupVM type, plan.code
    else if type in ['group', 'expensed']
      paymentMethod = { plan: plan.code, multiple: yes }
      getGroup().makePayment paymentMethod, (err, result)->
        return KD.showError err  if err
        vmController.createGroupVM type, plan.code
    else
      plan.subscribe multiple: yes, (err, result)->
        return KD.showError err  if err
        vmController.createGroupVM type, plan.code

  deleteVM: (vmInfo, callback) ->
    type  =
      if (vmInfo.planOwner.indexOf 'user_') > -1 then 'user'
      else if vmInfo.type is 'expensed'          then 'expensed'
      else 'group'

    @fetchSubscription getGroup(), type, vmInfo.planCode,\
      @createDeleteConfirmationModal.bind this, type, callback

  # views

  fetchPaymentInfo: (type, callback) ->

    { JPaymentPlan } = KD.remote.api

    switch type
      when 'group', 'expensed'
        getGroup().fetchPaymentInfo callback
      when 'user'
        JPaymentPlan.fetchAccountDetails callback

  updatePaymentInfo: (paymentMethodId, paymentMethod, callback) ->

    { JPayment } = KD.remote.api

    JPayment.setPaymentInfo paymentMethodId, paymentMethod, callback


  createPaymentInfoModal: ->

    modal = new PaymentFormModal
#
#    @fetchCountryData (err, countries, countryOfIp) =>
#      modal.setCountryData { countries, countryOfIp }

    return modal

  fetchCountryData:(callback)->

    { JPayment } = KD.remote.api

    if @countries or @countryOfIp
      return @utils.defer => callback null, @countries, @countryOfIp

    ip = $.cookie 'clientIPAddress'

    JPayment.fetchCountryDataByIp ip, (err, @countries, @countryOfIp) =>
      callback err, @countries, @countryOfIp

  # createPaymentConfirmationModal: (options, callback)->
  #   options.callback or= callback
  #   return new PaymentConfirmationModal options

  createDeleteConfirmationModal: (type, callback, subscription)->
    return new PaymentDeleteConfirmationModal { subscription, type, callback }
