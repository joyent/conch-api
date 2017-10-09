import m from "mithril";
import t from "i18n4v";
import Relay from "../../models/Relay";

export default {
    loading: true,

    oninit: ({ state }) => {
        Relay.loadRelays().then(() => (state.loading = false));
    },

    view: ({ state, attrs }) => {
        if (state.loading) return m(".loading", t("Loading..."));

        if (attrs.id) Relay.current = Relay.list.find(({id}) => id === attrs.id);
        else Relay.current = null;

        return Relay.list.map(relay => {
            return m(
                "a.selection-list-item",
                {
                    href: `/relay/${relay.id}`,
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
