var m = require("mithril");

module.exports = {
    view: function(vnode) {
        return m("main.layout", [
            m("nav.menu", [
                m("a[href='/racks']", {oncreate: m.route.link}, "Racks")
            ]),
            m("section", vnode.children)
        ]);
    }
};
