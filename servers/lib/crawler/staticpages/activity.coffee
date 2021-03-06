{ uri } = require 'koding-config-manager'


getAvatarImageUrl = (hash, avatar, size = 38) ->
  imgURL   = "//gravatar.com/avatar/#{hash}?size=#{size}&d=https://koding-cdn.s3.amazonaws.com/images/default.avatar.140.png&r=g"
  if avatar
    imgURL = "/-/image/cache?endpoint=crop&grow=false&width=#{size}&height=#{size}&url=#{encodeURIComponent avatar}"
  return imgURL

createAvatarImage = (hash, avatar, size = 38) ->
  imgURL = getAvatarImageUrl hash, avatar, size
  """
  <img width="#{size}" height="#{size}" src="#{imgURL}" style="opacity: 1;" itemprop="image" />
  """

createCreationDate = (createdAt, slug) ->
  """
  <time class="kdview" itemprop="dateCreated">#{createdAt}</time>
  """

createAuthor = (accountName, nickname) ->
  return "<a href=\"#{uri.address}/#{nickname}\"><span itemprop=\"name\">#{accountName}</span></a>"

prepareComments = (activityContent) ->
  commentsList = ''
  return commentsList  unless activityContent?.replies

  activityContent.replies.reverse()
  for comment in activityContent.replies
    { replier, message }                 = comment
    { createdAt }                        = message
    { hash, avatar, nickname, fullName } = replier
    createdAt                            = createCreationDate createdAt
    avatarImage                          = createAvatarImage hash, avatar, 30

    commentsList +=
      """
      <div class="kdview kdlistitemview kdlistitemview-comment">
        <a class="avatarview" href="/#{nickname}" style="background-image: none; background-size: 38px 38px;">
          #{avatarImage}
        </a>
        <div class="comment-contents clearfix">
          <a href="#{uri.address}/#{nickname}" class="profile" itemprop="name">#{fullName}</a>
          <div class="comment-body-container has-markdown">
            <p itemprop="commentText">#{message.body}</p>
          </div>
          #{createdAt}
        </div>
      </div>

      """

  return commentsList


getActivityContent = (activityContent) ->
  slugWithDomain = "#{uri.address}/Activity/Post/#{activityContent.slug}"
  { body, nickname, fullName, hash, avatar, createdAt, commentCount, likeCount } = activityContent
  location = activityContent?.payload?.location
  if location
    location = "from #{location}"
  else
    location = ''

  avatarImage   = createAvatarImage hash, avatar
  createdAt     = createCreationDate createdAt, activityContent.slug
  author        = createAuthor fullName, nickname

  displayCommentCount = if commentCount then commentCount else ''

  { formatBody } = require './bodyrenderer'
  body           = formatBody body
  commentsList   = prepareComments activityContent
  repliesCount   = activityContent.replies?.length
  count          = Math.min (commentCount - repliesCount), 10

  repliesText    = if count is 1
  then 'There is one comment above, please login to see.'
  else "There are #{count} comments above, please login to see."

  repliesLink    = if count > 0
  then "<a class='custom-link-view list-previous-link' href='/Login'>#{repliesText}</a>"
  else ''

  hasComments    = if repliesCount > 0
  then 'has-comments'
  else 'no-comments'

  content  =
    """
    <div class="kdview kdlistitemview kdlistitemview-activity static activity-item status">
      <div class="activity-content-wrapper">
        <a class="avatarview author-avatar" href="#{uri.address}/#{nickname}" style="background-image: none; background-size: 37px 37px;">
          #{avatarImage}
        </a>
        <div class="meta">
          <a href="#{uri.address}/#{nickname}" class="profile">#{fullName}</a>
          <div>
          <a href="#{slugWithDomain}">#{createdAt}</a>
          <span class="location">#{location}</span>
          </div>
        </div>
        <article class="has-markdown">
          #{body}
        </article>
        <div class="kdview activity-actions comment-header">
          <span class="logged-in action-container">
            <a class="custom-link-view" href="/Register">
              <span class="title">Comment</span>
            </a>
            <a class="custom-link-view #{if commentCount then 'count'}" href="/Register">
              <span>#{displayCommentCount}</span>
            </a>
          </span>
        </div>
      </div>
      <div class="kdview comment-container static #{hasComments}">
        #{repliesLink}
        <div class="kdview listview-wrapper">
          <div class="kdview kdscrollview">
            <div class="kdview kdlistview kdlistview-comments">
              #{commentsList}
            </div>
          </div>
        </div>
      </div>
      </div>
    """
  return content

module.exports = {
  getAvatarImageUrl
  getActivityContent
}
