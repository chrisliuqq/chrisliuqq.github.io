const nameReplace = [
    ['氷砕竜', '冰土砂龍'],
    ['桜火竜', '櫻火龍'],
    ['雌火竜', '雌火龍'],
    ['白兎獣', '白兔獸'],
    ['氷牙竜', '冰牙龍'],
    ['蛮顎竜', '蠻顎龍'],
    ['滅尽龍', '滅盡龍'],
    ['竜', '龍'],
    ['虫', '蟲'],
    ['獣', '獸']
];

Array.prototype.union = function(a)
{
    var r = this.slice(0);
    a.forEach(function(i) { if (r.indexOf(i) < 0) r.push(i); });
    return r;
};

function setCookie(name,value,days) {
    var expires = "";
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days*24*60*60*1000));
        expires = "; expires=" + date.toUTCString();
    }
    document.cookie = name + "=" + (value || "")  + expires + "; path=/";
}
function getCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
}
function eraseCookie(name) {
    document.cookie = name +'=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;';
}

const app = Vue.createApp({
    setup() {
        const monsters = Vue.reactive([]);
        const monsters2 = Vue.reactive([]);
        const keyword = Vue.ref('');
        const shortcuts = Vue.reactive([]);

        return {monsters, monsters2, keyword, shortcuts};
    },
    created() {
        let self = this;
        var content = getCookie('shortcuts');
        if (content) {
            self.shortcuts = Vue.reactive(content.split('|'));
        }
    },
    computed: {
        showResult() {
            let self = this;
            if (self.keyword.length <= 0) {
                return self.monsters;
            }

            var keywords = self.keyword.split(' ').filter( x => x.length > 0);

            if (keywords.length <= 0) {
                return self.monsters;
            }

            var result = self.monsters;
            result = self.monsters.filter( m => m.name.indexOf(keywords[0]) >= 0);

            if (keywords.length === 1) {
                return result;
            }

            result = result.map(x => x.name);

            for(var i = 1; i <= keywords.length - 1; i++) {
                result = result.union(self.monsters.map(x => x.name).filter( m => m.indexOf(keywords[i]) >= 0));
            }

            return self.monsters.filter( m => result.indexOf(m.name) >= 0);
        },
        showResult2() {
            let self = this;
            if (self.keyword.length <= 0) {
                return self.monsters2;
            }

            var keywords = self.keyword.split(' ').filter( x => x.length > 0);

            if (keywords.length <= 0) {
                return self.monsters2;
            }

            var result = self.monsters2;
            result = self.monsters2.filter( m => m.name.indexOf(keywords[0]) >= 0);

            if (keywords.length === 1) {
                return result;
            }

            result = result.map(x => x.name);

            for(var i = 1; i <= keywords.length - 1; i++) {
                result = result.union(self.monsters2.map(x => x.name).filter( m => m.indexOf(keywords[i]) >= 0));
            }

            return self.monsters2.filter( m => result.indexOf(m.name) >= 0);
        },
    },
    methods: {
        addCurrentToShortCuts() {
            let self = this;
            if (self.keyword.length <= 0) {
                return;
            }
            self.shortcuts.push(self.keyword);
            self.updateCookie();
        },
        removeShortCut(i) {
            let self = this;
            self.shortcuts.splice(i, 1);
            self.updateCookie();
        },
        switchKeywords(sc) {
            let self = this;
            self.keyword = sc;
        },
        updateCookie() {
            let self = this;
            var content = self.shortcuts.join('|');
            setCookie('shortcuts', content, 365);
        },
        parser(data) {
            let self = this;
            if (!data || !(data.hasOwnProperty('feed')) || !('entry' in data.feed)) {
                return;
            }
            data.feed.entry.forEach(function(m) {
                var monster = {};
                var name = self.replaceName(m['gsx$魔物']['$t'].trim());
                if(name) {
                    monster.name = name;
                    monster.weakPartMain = m['gsx$主要沒部位時']['$t'].trim();
                    monster.mainAttack = m['gsx$平常狀態力技速']['$t'].trim();
                    monster.weakAttr = m['gsx$弱點屬性']['$t'].trim();
                    monster.angryAttack = m['gsx$發怒狀態力技速']['$t'].trim();
                    monster.weakPartHead = m['gsx$頭斬刺打']['$t'].trim();
                    monster.weakPartWing = m['gsx$翼斬刺打']['$t'].trim();
                    monster.weakPartBelly = m['gsx$腹斬刺打']['$t'].trim();
                    monster.weakPartBody = m['gsx$身體斬刺打']['$t'].trim();
                    monster.weakPartFoot = m['gsx$腳斬刺打']['$t'].trim();
                    monster.weakPartTail = m['gsx$尾斬刺打']['$t'].trim();
                    self.monsters.push(monster);
                }
            });
        },
        parser2(data) {
            let self = this;
            if (!data || !(data.hasOwnProperty('feed')) || !('entry' in data.feed)) {
                return;
            }
            data.feed.entry.forEach(function(m) {
                var monster = {};
                var name = self.replaceName(m['gsx$魔物']['$t'].trim());
                if(name) {
                    monster.name = name;
                    // monster.weakPartMain = m['gsx$主要沒部位時']['$t'].trim();
                    monster.mainAttack = m['gsx$普通狀態']['$t'].trim();
                    monster.weakAttr = m['gsx$弱點屬性']['$t'].trim();
                    monster.angryAttack = m['gsx$生氣狀態']['$t'].trim();
                    monster.weakPartHead = m['gsx$頭部']['$t'].trim();
                    monster.weakPartWing = m['gsx$翅膀']['$t'].trim();
                    monster.weakPartBelly = m['gsx$腹部']['$t'].trim();
                    monster.weakPartBody = m['gsx$身體']['$t'].trim();
                    monster.weakPartFoot = m['gsx$腳']['$t'].trim();
                    monster.weakPartTail = m['gsx$尾巴']['$t'].trim();
                    monster.requireLevel = m['gsx$可掃蕩等級']['$t'].trim();
                    monster.home = m['gsx$歸巢加成']['$t'].trim();
                    self.monsters2.push(monster);
                }
            });
        },
        replaceName(name) {
            nameReplace.forEach(function(r) {
                name = name.replace(r[0], r[1]);
            });
            return name;
        },
        replaceAttackType(input) {
            input = input.replace(/技巧|技/, '<span><span class="bg-green-500 text-white weak-p">技巧</span></span>');
            input = input.replace(/力量|力/, '<span><span class="bg-red-500 text-white weak-s">力量</span></span>');
            return input.replace(/速度|速/, '<span><span class="bg-blue-500 text-white weak-t">速度</span></span>');
        },
    }
});

const vm = app.mount('#app');

vm.parser('test');