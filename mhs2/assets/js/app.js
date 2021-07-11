const nameReplace = [
    ['竜', '龍'],
    ['虫', '蟲']
];
const app = Vue.createApp({
    setup() {
        const monsters = Vue.reactive([]);
        const keyword = Vue.ref('');

        return {monsters, keyword};
    },
    computed: {
        showResult() {
            let self = this;
            if (self.keyword.length <= 0) {
                return self.monsters;
            }

            return self.monsters.filter( m => m.name.indexOf(self.keyword) >= 0);
        }
    },
    methods: {
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
        replaceName(name) {
            nameReplace.forEach(function(r) {
                name = name.replace(r[0], r[1]);
            });
            return name;
        }
    }
});

const vm = app.mount('#app');

vm.parser('test');