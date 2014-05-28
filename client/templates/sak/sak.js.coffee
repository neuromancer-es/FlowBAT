Template.sak.helpers
  isEdited: ->
    share.SakEditor.isEdited(@_id)
  isAddingTalk: ->
    share.SakEditor.isAddingTalk(@_id)
  addTalkSearchResults: ->
    addTalkQuery = Session.get("add-talk-query")
    if addTalkQuery
      regexp = new RegExp(addTalkQuery, "gi")
      talksGroupedByUserId = _.groupBy(@talks().fetch(), "userId")
      Meteor.users.find({"profile.name": regexp}, {limit: 9, sort: {createdAt: 1}, transform: (user) ->
        userTalks = talksGroupedByUserId[user._id]
        user.talkCount = if userTalks then userTalks.length else 0
        user
      })
    else
      []
  durationOverflowClass: ->
    if not @maximumDuration
      return ""
    if @calculatedDurationSum() > @maximumDuration
      return "text-danger"
    else
      return "text-success"

Template.sak.rendered = ->
  @$(".talks").sortable(
    axis: "y"
    delay: 75
    distance: 4
    handle: ".sortable-handle"
    cursor: "move"
    tolerance: "pointer"
    forceHelperSize: true
    forcePlaceholderSize: true
    placeholder: "object talk placeholder"
#    start: (event, ui) ->
#      ui.item.addClass("prevent-click")
#    stop: (event, ui) ->
#      _.defer ->
#        ui.item.removeClass("prevent-click") # prevent click after drag in Firefox
    update: (event, ui) ->
      if ui.sender # duplicate "update" event
        return
      $talk = ui.item
      talkId = $talk.attr("data-id")
      prevTalkId = $talk.prev().attr("data-id")
      nextTalkId = $talk.next().attr("data-id")
      if !prevTalkId && !nextTalkId
        position = 1
      else if !prevTalkId
        position = share.Talks.findOne(nextTalkId).position - 1
      else if !nextTalkId
        position = share.Talks.findOne(prevTalkId).position + 1
      else
        position = (share.Talks.findOne(nextTalkId).position + share.Talks.findOne(prevTalkId).position) / 2
      talk = share.Talks.findOne(talkId)
      $set = {position: position}
      share.Talks.update(talkId, {$set: $set})
  )

Template.sak.events
  "click .start-editing": encapsulate (event, template) ->
    share.EditorCache.stopEditing(template.data._id)
    share.SakEditor.startEditing(template.data._id, $(event.currentTarget).attr("data-edited-property"))
  "click .stop-editing": encapsulate (event, template) ->
    share.SakEditor.stopEditing(template.data._id)
  "click .remove": grab encapsulate (event, template) ->
    $target = $(event.currentTarget)
    confirmation = $target.attr("data-confirmation")
    if (not confirmation or confirm(confirmation))
      share.SakEditor.remove(template.data._id)
  "submit .object form": grab encapsulate (event, template) ->
    share.SakEditor.stopEditing(template.data._id)
  "click .add-talk": grab encapsulate (event, template) ->
    share.EditorCache.stopEditing()
    share.SakEditor.startAddingTalk(template.data._id)
    _.defer ->
      $(".add-talk-wrapper input").first().focus()
  "click .add-talk-wrapper .cancel": grab encapsulate (event, template) ->
    share.EditorCache.stopEditing()
    share.SakEditor.stopAddingTalk(template.data._id)
    Session.set("add-talk-query", "")
  "input .add-talk-query": encapsulate (event, template) ->
    Session.set("add-talk-query", $(event.currentTarget).val())
  "click .add-talk-wrapper .user": encapsulate (event, template) ->
    $user = $(event.currentTarget)
    talkCount = $user.attr("data-talk-count")
    if talkCount < 2
      _id = share.SakEditor.insertTalk(template.data._id,
        userId: $user.attr("data-id")
        isNew: false
      )
      share.TalkEditor.stopEditing(_id)
#      Session.set("add-talk-query", "")
#      template.$(".add-talk-wrapper input").first().val("").focus()
