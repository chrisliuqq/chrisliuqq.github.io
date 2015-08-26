###
https://spreadsheets.google.com/feeds/worksheets/{SHEET-ID}/public/basic?alt=json       get grid ids
https://spreadsheets.google.com/feeds/list/{SHEET-ID}/{GRID-ID}/public/values?alt=json  get whole sheet data
https://spreadsheets.google.com/feeds/cells/{SHEET-ID}/{GRID-ID}/public/values          get all cell data
alt=json                                                                                return json
alt=json-in-script&callback={CALLBACK}                                                  return data to callback function
###

loadingTimeout = null

Array.prototype.unique = () ->
    a = [];
    for i in [0...this.length]
        if (a.indexOf(this[i]) == -1)
            a.push(this[i]);
    return a;

PreInit = () ->
    $("#overlay-loading-announce .content").html("<p>" + $("#update-modal dt:first").html() + "</p>")
    Setting.init()

updateTimeout = () ->
    clearTimeout(loadingTimeout)
    loadingTimeout = setTimeout ->
        if $("#overlay-loading").length
            $("#overlay-loading-notification").html('距離讀取上一個題庫資料已經超過 10 秒了，有可能 wikia 發生錯誤，您如果處於網路品質較差的情況下可繼續等待，或者<a class="btn btn-default" href="javascript:location.reload();">按此重新整理</a>試試看')
    , 10000
    return

Setting =
    localStorage: false
    cache:
        adLoading: "1"
        searchMinLength: "1"

    init: ->
        Setting.localStorage = Setting.localStorageSupport()
        if Setting.localStorage
            localSetting = localStorage.getItem("wizSetting")
        else
            localSetting = util.getCookie("wizSetting")

        Setting.cache = $.extend({}, Setting.cache, JSON.parse(localSetting))

        for own key, result of Setting.cache
            $('.' + key ).val(result)

        if Setting.get("adLoading") != "1"
            $("#overlay-loading-ad").remove()

    get: (key) ->
        Setting.cache[key]

    save: (json)->
        localSetting = {}
        for v,k in json
            localSetting[v.name] = v.value

        Setting.cache = localSetting

        if Setting.localStorage == true
            localStorage.setItem("wizSetting", JSON.stringify(localSetting))
        else
            util.setCookie("wizSetting", JSON.stringify(localSetting), "")

    localStorageSupport: ->
        try
            localStorage.setItem("test", "test")
            localStorage.removeItem("test")
            return true
        catch e
            return false

        return

class util
    @pop: (obj) ->
        for own key, result of obj
            if !delete obj[key]
                throw new Error()
            return result
    @cleanObject: (obj) ->
        return util.pop(util.pop(util.pop(obj)))
    @parseContent: (obj) ->
        return obj.revisions[0]["*"]
    @parseType: (obj) ->
        return obj.title.match(/模板:題庫\/([^\/]+)?/).slice(1).join()

    @htmlEncode: ( html ) ->
        return document.createElement( 'a' ).appendChild(document.createTextNode( html ) ).parentNode.innerHTML

    @highlight: ( keyword, msg) ->
        if Array.isArray(keyword)
            for kw in keyword
                msg = msg.split(kw).join("<b>#{kw}</b>")
        else
            msg = msg.split(keyword).join("<b>#{keyword}</b>")
        return msg
    @getRandomInt: (min, max) ->
        return Math.floor(Math.random() * (max - min)) + min;

    @setCookie = (name, value, days) ->
        if days
            date = new Date()
            date.setTime date.getTime() + (days * 24 * 60 * 60 * 1000)
            expires = "; expires=" + date.toGMTString()
        else
            expires = ""
            document.cookie = name + "=" + value + expires + "; path=/"
    @getCookie = (name) ->
        nameEQ = name + "="
        ca = document.cookie.split(";")
        i = 0

        while i < ca.length
            c = ca[i]
            c = c.substring(1, c.length)  while c.charAt(0) is " "
            return c.substring(nameEQ.length, c.length)  if c.indexOf(nameEQ) is 0
            i++
    null

    @deleteCookie = (name) ->
        @setCookie name, "", -1

class wizLoader

    @data:
        totalQuestion: 0
        totalPage: 0
        loadQuestion: 0
        loadedPage: 0
        loadedType: 0

        db: TAFFY()

    @option:
        type: ['四選一', '每日', '排序']
        # type: ['四選一']

    @queryMaxId = (type) ->
        $.ajax
            # url: "http://zh.nekowiz.wikia.com/wiki/模板:題庫/#{type}?action=raw"
            url: "http://zh.nekowiz.wikia.com/api.php"
            crossDomain: true
            dataType: "jsonp"
            data:
                format: "json"
                callback: "wizLoader.queryMaxIdCallback"
                action: "query"
                prop: "revisions"
                titles: "模板:題庫/#{type}"
                rvprop: "content"

    @queryMaxIdCallback = (data) ->
        data = util.cleanObject(data)
        type = util.parseType(data)
        maxId = parseInt(util.parseContent(data))
        maxPage = (Math.floor((maxId - 1) / 500) + 1)
        wizLoader.data.totalQuestion += maxId
        wizLoader.data.totalPage += maxPage
        @queryQuestion(type, maxPage)

    @queryQuestionCallback = (data) ->
        data = util.cleanObject(data)
        type = util.parseType(data)
        content = util.parseContent(data)
        db = []
        for line in content.split("\n")
            question = line.split("|")
            if type == "四選一"
                db.push({ id: question[0], type: type, question: question[2], answer: question[3], subType: question[1], color: question[4], fulltext: "#{question[2]}#{question[3]}".toLowerCase() })
            else if type == "排序"
                db.push({ id: question[0], type: type, question: question[1], answer: question.slice(2).join("、"), fulltext: question.slice(1).join("").toLowerCase() })
            else
                db.push({ id: question[0], type: type, question: question[1], answer: question[2], fulltext: "#{question[1]}#{question[2]}".toLowerCase(), imgname: question[3] })
            wizLoader.data.loadQuestion++
            # UI.updateNotification("#{wizLoader.data.loadQuestion}/#{wizLoader.data.totalQuestion}")
        UI.updateProcessbar("#{wizLoader.data.loadQuestion}/#{wizLoader.data.totalQuestion}", Math.floor(wizLoader.data.loadQuestion*100/wizLoader.data.totalQuestion) )
        wizLoader.data.db.insert(db)
        updateTimeout()
        if ++wizLoader.data.loadedPage == wizLoader.data.totalPage
            UI.init()

        return

    ###
    四選一：題號|type|題目|答案|顏色
    每日：題號|題目|答案|圖片檔名
    排序：題號|題目|答案1|答案2|答案3|答案4
    ###
    @queryQuestion = (type, maxPage) ->
        loadedPage = 0
        for page in [1...(maxPage+1)]
            $.ajax
                url: "http://zh.nekowiz.wikia.com/api.php"
                crossDomain: true
                dataType: "jsonp"
                data:
                    format: "json"
                    callback: "wizLoader.queryQuestionCallback"
                    action: "query"
                    prop: "revisions"
                    titles: "模板:題庫/#{type}/#{page}"
                    rvprop: "content"

    @load: () ->
        for type in @option.type
            @queryMaxId(type);
        return

    @init: () ->
        @load()
        # UI.init()

UI =
    init: () ->
        clearTimeout(loadingTimeout)
        $("#load-count").text("讀取 #{wizLoader.data.totalQuestion} 個問題。")
        $("#overlay-loading").remove()
        $("#btn-hide-footer").click () ->
            $("#footer").hide()
        $(".form").submit (e) ->
            e.preventDefault()
            false

        $(".from-source").on "change", ->
            $("#inputKeyword").trigger "keyup"

        $("#result").on "click", ".btn-more", ->
            tr = $(this).parents("tr")
            type = tr.data("type");
            pos = tr.data("pos");
            trOffset = tr.offset();
            data = wizLoader.data.db({type: type},{id: "#{pos}"}).first()
            text = ''
            if type == '四選一'
                text = "題目顏色：#{data.color}，題目類型：#{data.subType}"

            # text += "，，<a id=\"question-report\" href=\"javascript:void\" data-question=\"#{data.question}\" data-answer=\"#{data.answer}\">錯誤回報</a>"
            $("#question-info").css({ top: trOffset.top,left: trOffset.left,width: tr.width(),height: tr.height()}).addClass("active")
            $("#question-info .info div").html(text)

        $("#question-info").on "click", ".btn-close", ->
            return $("#question-info").removeClass("active")

        # $("#question-info").on "click", "#question-report", ->
        #     question = encodeURIComponent($(this).data("question"))
        #     answer = encodeURIComponent($(this).data("answer"))
        #     url = "https://docs.google.com/forms/d/1GYyqSKOfF2KMkMGfEuKtyE8oZadgTRRj_ZClYZRX2Qc/viewform?entry.699244241=%E9%A1%8C%E7%9B%AE%EF%BC%9A#{question}%0A%E5%8E%9F%E5%A7%8B%E7%AD%94%E6%A1%88%EF%BC%9A#{answer}%0A%E6%AD%A3%E7%A2%BA%E7%AD%94%E6%A1%88%EF%BC%9A";
        #     $("#report-modal iframe").attr("src", url)
        #     $('#report-modal').modal('show')

        $("#inputKeyword").on "keyup", ->
            val = $(this).val()

            $("#question-info").removeClass("active")
            $("#result").html("")

            if val.length < Setting.get("searchMinLength")
                return

            val = val.toLowerCase()
            type = $(".from-source:checked").map () ->
                return this.value
            .get()

            result = null

            try
                if val.split(" ").length > 1
                    val = val.split(" ")
                    val = val.unique()
                    for v,i in val
                        if (v == "")
                            delete val[i]

                    result = wizLoader.data.db(() ->

                        if $.inArray(this.type, type) == -1
                            return false

                        for keyword in val
                            if (this.fulltext.indexOf(keyword) == -1)
                                return false
                        return true
                    )
                else
                    val = [val]
                    result = wizLoader.data.db({type: type},{fulltext: {likenocase: val}})
            catch
                return

            html = ""

            result.each (r) ->

                if typeof(r.question) == "undefined"
                    return true

                if r.type == "四選一"

                    html += '<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more"><a href="javascript:void(0);" class="btn-more">更多</a></td><td><div class="question">' + util.highlight(val, r.question) + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>'

                    # $("#result").append('<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more"><a href="javascript:void(0);" class="btn-more">更多</a></td><td><div class="question">' + util.highlight(val, r.question) + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>');
                else if r.type == "排序"

                    html += '<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more"><a href="javascript:void(0);" class="btn-more">更多</a></td><td><div class="question">' + util.highlight(val, r.question) + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>'

                    # $("#result").append('<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more"><a href="javascript:void(0);" class="btn-more">更多</a></td><td><div class="question">' + util.highlight(val, r.question) + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>');
                else
                    md5name = CryptoJS.MD5(r.imgname).toString()
                    imgurl = "http://vignette#{util.getRandomInt(1,5)}.wikia.nocookie.net/nekowiz/images/#{md5name.charAt(0)}/#{md5name.charAt(0)}#{md5name.charAt(1)}/#{r.imgname}/revision/latest?path-prefix=zh"

                    html += '<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more"><!--<a href="javascript:void(0);" class="btn-more">更多</a>--></td><td><div class="col-sm-3"><img src="' + imgurl + '" /></div><div class="col-sm-5">' + util.highlight(val, r.question) + '</div><div class="col-sm-4 text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>'

                    # $("#result").append('<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more"><!--<a href="javascript:void(0);" class="btn-more">更多</a>--></td><td><div class="col-sm-3"><img src="' + imgurl + '" /></div><div class="col-sm-5">' + util.highlight(val, r.question) + '</div><div class="col-sm-4 text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>');

            $("#result").append(html)

            return

        $(".list-type, .list-stype, .list-color").on "change", ->

            type = $(".list-type:checked").val()
            stype = ""
            color = ""
            result = null

            if type == "四選一"
                $(".list-detail").show()
                stype = $(".list-stype:checked").val()
                color = $(".list-color:checked").val()

                if stype != "all" && color != "all"
                    result = wizLoader.data.db({type: type},{subType: stype},{color: color})
                else if stype != "all"
                    result = wizLoader.data.db({type: type},{subType: stype})
                else if color != "all"
                    result = wizLoader.data.db({type: type},{color: color})
                else
                    result = wizLoader.data.db({type: type})
            else
                $(".list-detail").hide()
                result = wizLoader.data.db({type: type})

            $("#result-list").html("")

            html = ""

            result.each (r) ->
                if r.type == "四選一"

                    html += '<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more">' + r.id + '</td><td><div class="question">' + r.question + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>'

                    # $("#result-list").append('<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more">' + r.id + '</td><td><div class="question">' + r.question + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>');
                else if r.type == "排序"

                    html += '<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more">' + r.id + '</td><td><div class="question">' + r.question + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>'

                    # $("#result-list").append('<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more">' + r.id + '</td><td><div class="question">' + r.question + '</div><div class="text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>');
                else
                    md5name = CryptoJS.MD5(r.imgname).toString()
                    imgurl = "http://vignette#{util.getRandomInt(1,5)}.wikia.nocookie.net/nekowiz/images/#{md5name.charAt(0)}/#{md5name.charAt(0)}#{md5name.charAt(1)}/#{r.imgname}/revision/latest?path-prefix=zh"

                    html += '<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more">' + r.id + '</td><td><div class="col-sm-3"><img src="' + imgurl + '" /></div><div class="col-sm-5">' + r.question + '</div><div class="col-sm-4 text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>'
                    # $("#result").append('<tr data-pos="' + r.id + '" data-type="' + r.type + '"><td class="td-more">' + r.id + '</td><td><div class="col-sm-3"><img src="' + imgurl + '" /></div><div class="col-sm-5">' + r.question + '</div><div class="col-sm-4 text-danger">' + util.htmlEncode(r.answer) + '</div></td></tr>');

            $("#result-list").append(html)

            return

        $("#form-setting").on "submit", (e) ->
            e.preventDefault()
            Setting.save($("#form-setting").serializeArray())
            $('#setting-modal').modal('hide')
            return false

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

###
class wizLoader
    @data =
        normal: []
        sort: []
        daily: []
        count: 0

    @option =
        sheedId: "1wzAwAH4rJ72Zw6r-bjoUujfS5SMOEr38s99NxKmNk4g"
        gridIds:
            '四排序題':     'o5ocq9n'
            '每日問答':     'oqqi90o'
            # '總覽':       'o6hvqd7'
            '黑貓題庫(表單填寫)':     'oj7l0gb'
        loadCount: 0

    @addScript: (gridEntry) ->
        src = "https://spreadsheets.google.com/feeds/cells/#{@option.sheedId}/#{gridEntry}/public/values?alt=json-in-script&callback=wizLoader.load"
        s = document.createElement( 'script' )
        s.setAttribute( 'src', src )
        document.body.appendChild( s )

    @load: (data) ->
        tmp = data.feed.id.$t.split('/')
        if tmp.length == 9
            if tmp[6] == 'o5ocq9n'
                return @_loadSort (data.feed.entry)
            if tmp[6] == 'oqqi90o'
                return @_loadDaily (data.feed.entry)

            return @_loadNormal (data.feed.entry)

    @_loadNormal: (data) ->
        # 2: color, 3: type
        tmp = {}
        col = 0
        keys = ['','','color','type','question','answer']
        for index, entry of data
            if (parseInt(entry.gs$cell.row) <= 1 )
                continue

            col = parseInt(entry.gs$cell.col)

            if col >= 2 && col <= 5

                if col == 2
                    tmp = {}

                tmp[keys[col]] = entry.content.$t

                if col == 5
                    @data.normal.push(tmp)


        return @_loadComplete()
    @_loadSort: (data) ->
        tmp = []
        col = 0
        for index, entry of data
            if (parseInt(entry.gs$cell.row) <= 2 )
                continue;
            col = parseInt(entry.gs$cell.col)
            if ( col >= 2 && col <= 6 )
                    if (col == 2)
                        tmp = []
                    tmp.push(entry.content.$t)
                    if (col == 6)
                        @data.sort.push(tmp)

        return @_loadComplete()

    @_loadDaily: (data) ->
        # 2 url, 4 question, 5 answer
        tmp = []
        col = 0
        for index, entry of data
            if (parseInt(entry.gs$cell.row) <= 2 )
                continue;
            col = parseInt(entry.gs$cell.col)
            if col == 3
                continue

            if col >= 2 && col <= 5
                if col == 2
                    tmp = [];
                tmp.push(entry.content.$t)
                if (col == 5)
                    @data.daily.push(tmp)

        return @_loadComplete()

    @_loadComplete: () ->
        @data.count++
        if @data.count == Object.keys(@option.gridIds).length
            $("#overlay-loading").remove();
            $("#load-count").text('共讀取了 ' + (@data.normal.length + @data.sort.length + @data.daily.length ) + ' 個問題。');
        else
            $("#loaded-count").text(@data.count + '/' + Object.keys(@option.gridIds).length);
        return
    @htmlEncode: ( html ) ->
        return document.createElement( 'a' ).appendChild(document.createTextNode( html ) ).parentNode.innerHTML

    @highlight: ( keyword, msg) ->
        msg.split(keyword).join("<b>#{keyword}</b>")

    @_initEvent: () ->
        $(".form").submit (e) ->
            e.preventDefault()
            false

        $(".from-source").on "change", ->
            $("#inputKeyword").trigger "keyup"

        $("#result").on "click", ".btn-more", ->
            tr = $(this).parents("tr")
            type = tr.data("type");
            pos = tr.data("pos");
            trOffset = tr.offset();
            data = {}
            text = ''
            if type == 'normal'
                data = wizLoader.data[type][pos]
                text = "題目顏色：#{data.color}，題目類型：#{data.type}，"
            else if type == 'daily'
                data =
                    question: "#{wizLoader.data[type][pos][1]}，網址：#{wizLoader.data[type][pos][0]}"
                    answer: wizLoader.data[type][pos][2]
            else
                data =
                    question: wizLoader.data[type][pos][0]
                    answer: wizLoader.data[type][pos].slice(1).join('、')

            text += "<a id=\"question-report\" href=\"javascript:void\" data-question=\"#{data.question}\" data-answer=\"#{data.answer}\">錯誤回報</a>"
            $("#question-info").css({ top: trOffset.top,left: trOffset.left,width: tr.width(),height: tr.height()}).addClass("active")
            $("#question-info .info div").html(text)

        $("#question-info").on "click", ".btn-close", ->
            return $("#question-info").removeClass("active")

        $("#question-info").on "click", "#question-report", ->
            question = encodeURIComponent($(this).data("question"))
            answer = encodeURIComponent($(this).data("answer"))
            url = "https://docs.google.com/forms/d/1GYyqSKOfF2KMkMGfEuKtyE8oZadgTRRj_ZClYZRX2Qc/viewform?entry.699244241=%E9%A1%8C%E7%9B%AE%EF%BC%9A#{question}%0A%E5%8E%9F%E5%A7%8B%E7%AD%94%E6%A1%88%EF%BC%9A#{answer}%0A%E6%AD%A3%E7%A2%BA%E7%AD%94%E6%A1%88%EF%BC%9A";
            $("#report-modal iframe").attr("src", url)
            $('#report-modal').modal('show')

        $("#inputKeyword").on "keyup", ->
            val = $(this).val()

            $("#question-info").removeClass("active")
            $("#result").html("")

            if val.length <= 0
                return

            val = val.toLowerCase()



            if $("#fromNormal:checked").val() == '1'
                for index, entry of wizLoader.data.normal
                    if typeof(entry.question) == 'undefined'
                        console.debug (entry)
                        continue

                    if entry.question.toLowerCase().indexOf(val) != -1
                        if (entry.question.toLowerCase().indexOf(val) != -1)
                            $("#result").append('<tr data-pos="' + index + '" data-type="normal"><td class="td-more"><a href="javascript:void(0);" class="btn-more">更多</a></td><td><div class="question">' + wizLoader.highlight(val, entry.question) + '</div><div class="text-danger">' + wizLoader.htmlEncode(entry.answer) + '</div></td></tr>');

            if $("#fromSort:checked").val() == '1'
                for index, entry of wizLoader.data.sort
                    if entry[0].toLowerCase().indexOf(val) != -1
                        $("#result").append('<tr><tr data-pos="' + index + '" data-type="sort"><td class="td-more"><a href="javascript:void(0);" class="btn-more">更多</a></td><td><div class="question">' + wizLoader.highlight(val, entry[0]) + '</div><div class="text-danger">' + wizLoader.htmlEncode(entry.slice(1).join('、')) + '</div></td></tr>');

            if $("#fromDaily:checked").val() == '1'
                for index, entry of wizLoader.data.daily
                    if entry[1].toLowerCase().indexOf(val) != -1
                        $("#result").append('<tr><tr data-pos="' + index + '" data-type="daily"><td class="td-more"><a href="javascript:void(0);" class="btn-more">更多</a></td><td><div class="col-sm-3"><img src="' + entry[0] + '" /></div><div class="col-sm-5">' + wizLoader.highlight(val, entry[1]) + '</div><div class="col-sm-4 text-danger">' + wizLoader.htmlEncode(entry[2]) + '</div></td></tr>');

            return

        return

    @init: () ->
        for type, entry of @option.gridIds
            @addScript (entry)
        @_initEvent()
        return
###

$ ->
    PreInit()
    wizLoader.init()