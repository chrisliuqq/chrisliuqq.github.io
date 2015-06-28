###
https://spreadsheets.google.com/feeds/worksheets/{SHEET-ID}/public/basic?alt=json       get grid ids
https://spreadsheets.google.com/feeds/list/{SHEET-ID}/{GRID-ID}/public/values?alt=json  get whole sheet data
https://spreadsheets.google.com/feeds/cells/{SHEET-ID}/{GRID-ID}/public/values          get all cell data
alt=json                                                                                return json
alt=json-in-script&callback={CALLBACK}                                                  return data to callback function
###

class util
    @pop: (obj) ->
        for own key, result of obj
            if !delete obj[key]
                throw new Error()
            return result
    @cleanObject: (obj) ->
        return util.pop(util.pop(util.pop(obj)))

    @htmlEncode: ( html ) ->
        return document.createElement( 'a' ).appendChild(document.createTextNode( html ) ).parentNode.innerHTML

    @highlight: ( keyword, msg) ->
        if Array.isArray(keyword)
            for kw in keyword
                msg = msg.split(kw).join("<b>#{kw}</b>")
        else
            msg = msg.split(keyword).join("<b>#{keyword}</b>")
        return msg

class dataLoader

    @data:
        totalQuestion: 0
        totalPage: 0
        loadQuestion: 0
        loadedPage: 0
        loadedType: 0

        db: TAFFY()

    @load: () ->

        $.ajax
            url: "https://gist.githubusercontent.com/tony1223/098e45623c73274f7ae3/raw"
            crossDomain: true
            dataType: "json"

        .done (data) ->
            # for d in data
            #     db.push({ name: d['姓名'] , })
            dataLoader.data.db.insert(data.data)
            $("#load-count").text("最後更新 #{data.lastmodify}")
            dataLoader.list()

    @list: () ->
        result = dataLoader.data.db()
        html = ""
        result.each (r) ->

                html += "<tr><td>#{r['姓名']}</td><td>#{r['性別']}</td><td>#{r['國籍']} - #{r['縣市別']}</td><td>#{r['年齡']}</td><td>#{r['收治單位']}/#{r['醫療檢傷']}/#{r['救護檢傷']}</td><td>#{r['即時動向']}</td></tr>"
                # html += '<tr"><td class="td-more"><a href="javascript:void(0);" class="btn-more">更多</a></td><td><div class="question">' + util.highlight(val, r.question) + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>'

            $("#result").append(html)

    @init: () ->
        @load()
        # UI.init()

UI =
    init: () ->

        $("#btn-hide-footer").click () ->
            $("#footer").hide()
        $(".form").submit (e) ->
            e.preventDefault()
            false

        $(".from-source").on "change", ->
            $("#inputKeyword").trigger "keyup"

        $("#inputKeyword").on "keyup", ->
            val = $(this).val()

            if (val.length <= 0)
                return dataLoader.list()

            $("#result").html("")

            val = val.toLowerCase()
            # if (val.length == 3)
            #     val = val[0] + '○' + val[2]

            result = dataLoader.data.db({"姓名": val})

            html = ""


            result.each (r) ->

                html += "<tr><td>#{r['姓名']}</td><td>#{r['性別']}</td><td>#{r['國籍']} - #{r['縣市別']}</td><td>#{r['年齡']}</td><td>#{r['收治單位']}/#{r['醫療檢傷']}/#{r['救護檢傷']}</td><td>#{r['即時動向']}</td></tr>"
                # html += '<tr"><td class="td-more"><a href="javascript:void(0);" class="btn-more">更多</a></td><td><div class="question">' + util.highlight(val, r.question) + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>'

            $("#result").append(html)

            return

    loading: (msg) ->
        if msg != ""
            $("#overlay-loading-content div").text(msg)
            $("#overlay-loading").show()
        else
            $("#overlay-loading").hide()
        return
    updateNotification: (msg) ->
        $("#loaded-count").text(msg)
    updateProcessbar: (msg, percent) ->
        $("#process-bar").text(msg).css("width", "#{percent}%");


$ ->
    dataLoader.init()
    UI.init()