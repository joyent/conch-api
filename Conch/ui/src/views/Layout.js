var m = require("mithril");
var t = require('i18n4v');


// Three-pane layout with two children. Additional children will not be rendered.
module.exports = {
    view: function(vnode) {
        return m("main.layout", [
            m(".pure-g",
                [
                    m(".pure-u.pure-menu#nav",
                        m("h1", t("Conch")),
                        m("ul.pure-menu-list",[

                            m("li.pure-menu-item",
                                m("a[href='/rack'].pure-menu-link.nav-link",
                                    {oncreate: m.route.link}, t("Racks"))
                            ),

                            m("li.pure-menu-item",
                                m("a[href='/problem'].pure-menu-link.nav-link",
                                    {oncreate: m.route.link}, t("Problems"))
                            ),

                            m("li.pure-menu-item",
                                m("a[href='/device'].pure-menu-link.nav-link",
                                    {oncreate: m.route.link}, t("Devices"))
                            ),

                        ])
                    ),
                    m(".selection-list.pure-u", vnode.children[0]),
                    m(".content-pane.pure-u-1-2", vnode.children[1])
            ]),
        ]);
    }
};
