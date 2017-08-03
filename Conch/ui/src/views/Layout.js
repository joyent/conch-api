var m = require("mithril");

module.exports = {
    view: function(vnode) {
        return m("main.layout", [
            m(".pure-g", [
                m(".pure-u-1-3",
                  m(".pure-menu.pure-menu-horizontal",
                    m("ul.pure-menu-list",[
                      m("li.pure-menu-item",
                        m("a[href='/racks'].pure-menu-link", {oncreate: m.route.link}, "Racks")
                      ),
                      m("li.pure-menu-item",
                        m("a[href='/problems'].pure-menu-link", {oncreate: m.route.link}, "Problems")
                      ),
                    ]
                  ))
                )
            ]),
            m("section", vnode.children)
        ]);
    }
};
