var bookingApp = null;
var url = 'https://spreadsheets.google.com/feeds/cells/1udT-VlDhek9vgtqLeikbDEj3OFlgr6PTjiaKh6dEv0Q/olc7b3g/public/basic?alt=json';

bookingApp = new Vue({
    el: '#main',
    data: {
        currentName: null,
        currentData: { B: 0, C: 0, D: 0, P: 0, S: null },
        dataRows: {}
    },
    computed: {
    },
    mounted: function() {
        var _this = this;
        // document.querySelector('.page-campaign-new').style.display = 'block';
        $.get(url, function(data) {
            var result = {};
            var tmp;
            var field = '';
            var value = '';
            var id = '';
            $.each(data.feed.entry, function(index, feed) {
                tmp = /([A-Z]+)([0-9]+)/.exec(feed['title']['$t']);
                if (tmp[2] === "1") {
                    return true;
                }

                value = feed['content']['$t'];

                if (tmp[1] === "A") {
                    result[value] = {};
                    id = value;
                }
                else {
                    result[id][tmp[1]] = value;
                }

            });
            _this.dataRows = result;
        }, 'json');
    },
    methods: {
        nameChange: function(event) {
            var name = event.target.value;
            if (this.dataRows.hasOwnProperty(name)) {
                var target = this.dataRows[name];
                var B = C = D = P = S = 0;
                if (target.D === '上冊：訂價600元，預購優惠價510元。(含郵資)') {
                    C = parseInt(target['E'], 10);
                }
                else if (target.D === '下冊：訂價600元，預購優惠價510元。(含郵資)') {
                    D = parseInt(target['E'], 10);
                }
                B = parseInt(target['C'], 10);
                P = B*960 + (C+D) * 510;
                this.currentData = { B: B, C: 0, D: 0, P: P, S: null };
            }
            else {
                this.currentData = { B: 0, C: 0, D: 0, P: 0, S: null };
            }
        }
    }
});
