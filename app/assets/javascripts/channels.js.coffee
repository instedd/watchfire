window.onChannelsIndex = ->
  $ ->
    $('#new_channel_kind').on 'change', ->
      window.location.href = '/channels/new?kind=' + @value
      @value = ''

    $('.link').click ->
      url = $(@).data('url')
      window.location = url

    $('.avoid').click (evt) ->
      evt.stopPropagation()

