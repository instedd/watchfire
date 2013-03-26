window.onChannelsIndex = ->
  $('#new_channel_kind').on 'change', ->
    window.location.href = '/channels/new?kind=' + @value
    @value = ''

