jQuery ->

  class ConsoleClient

    connect: () ->
      $.ajax
        url: "/start.json"
        success: (data) =>
          @connection_guid = data.guid
          $('.prompt:last').html data.lines[0]

          window.onbeforeunload = =>
            @disconnect()

          $(window).unload =>
            @disconnect()

    setup: (guid, prompt) ->
      @connection_guid = guid
      @last_prompt = prompt

    update_last_prompt: () ->
       $('.prompt:last').html @last_prompt

    talk: (msg, callback) ->
      $.ajax
        url: "/talk/#{@connection_guid}.json"
        type: 'post'
        data:
          msg: escape(msg)
        success: (data) =>
          callback data
    
    disconnect: () ->
      $.ajax
        url: "/talk/#{@connection_guid}.json"

    html_encode: (value) ->
      $("<div/>").text(value).html()

  window.ConsoleClient = ConsoleClient