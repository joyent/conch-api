const m = require("mithril");
const t = require("i18n4v");

const Relay = require("../../models/Relay");

module.exports = {
    loading: true,

    oninit: ({ state }) => {
        Relay.loadRelays().then(() => (state.loading = false));
    },

    view: ({ state, attrs }) => {
        if (state.loading) return m(".loading", t("Loading..."));

        if (attrs.id) Relay.current = Relay.list.find(r => r.id === attrs.id);
        else Relay.current = null;

        return Relay.list.map(relay => {
            return m(
                "a.selection-list-item",
                {
                    href: "/relay/" + relay.id,
                    onclick: () => {
                        Relay.current = relay;
                    },
                    oncreate: m.route.link,
                    class:
                        relay === Relay.current
                            ? "selection-list-item-active"
                            : "",
                },
                relay.alias || relay.id
            );
        });
    },
};
