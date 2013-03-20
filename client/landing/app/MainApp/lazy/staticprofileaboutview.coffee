class StaticProfileAboutView extends KDView
  constructor:(options,data)->
    super options,data

    @setClass 'profile-about-view'

    {about}   = @getOptions()
    {profile} = @getData()

    unless about
      @partial = 'Nothing here yet!'
    else
      @partial = Encoder.htmlDecode about.html or about.content

    @profileHeaderView = new StaticProfileAboutHeaderView
      cssClass : 'about-header'
    ,@getData()

    if KD.whoami().getId() is @getData().getId()
      @editButton = new KDButtonView
        title : 'Edit this page'
        cssClass : 'about-edit-button clean-gray'
        callback : =>
          @$('.about-body').addClass 'hidden'
          @editView.show()
      @editView = new KDView
        cssClass : 'hidden about-edit'

      @editView.addSubView @editForm = new KDInputViewWithPreview
        defaultValue : Encoder.htmlDecode(about.content)
        cssClass : 'about-edit-input'

      @editView.addSubView @saveButton = new KDButtonView
        title : 'Save'
        cssClass : 'about-save-button clean-gray'
        loader          :
          diameter      : 12
        callback:=>
          @saveButton.showLoader()
          @getData().setAbout Encoder.XSSEncode(@editForm.getValue()), =>
            log arguments
            @editView.hide()
            @$('.about-body').removeClass 'hidden'
            @saveButton.hideLoader()
    else
      @editButton = new KDView
        cssClass : 'hidden'
      @editView = new KDView
        cssClass : 'hidden'
  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @profileHeaderView}}
    {{> @editButton}}
    {{> @editView}}
    <div class="about-body">
      <div class="has-markdown">
        <span class="data">
          #{@partial}
        </span>
      </div>
    </div>

    """

class StaticProfileAboutHeaderView extends KDView
  constructor:(options,data)->
    super options,data

    {profile} = @getData()

    fallbackUri = "#{KD.apiUri}/images/defaultavatar/default.avatar.160.png"
    bgImg = "url(//gravatar.com/avatar/#{profile.hash}?size=#{160}&d=#{encodeURIComponent fallbackUri})"

    @$().css backgroundImage : bgImg

    @profileNicknameView = new KDView
      cssClass : 'nickname'
      partial : "@#{profile.nickname}"

    @profileNameView = new KDView
      cssClass : 'name'
      partial : [profile.firstName, profile.lastName].join ' '

    @profileLocationView = new KDView
      cssClass : 'location'
      partial : profile.locationTags?[0] or 'Earth'

    @profileAboutView = new KDView
      cssClass : 'about'
      partial : profile.about or ''

    @profileUserUrlView = new CustomLinkView
      cssClass : 'url'
      href : "http://#{profile.nickname}.koding.com"
      title : "#{profile.nickname}.koding.com"
      target : '_blank'

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="about-name">
      {{> @profileNameView}}
      {{> @profileLocationView}}
    </div>
    <div class="about-link">
      {{> @profileUserUrlView}}
    </div>
    <div class="about-about">
      {{> @profileAboutView}}
    </div>
    {{> @profileNicknameView}}
    """

