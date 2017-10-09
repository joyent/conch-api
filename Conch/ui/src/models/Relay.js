import m from "mithril";

// Use a natural sort with devices that end with a number.
// e.g, 'PRD10' comes after 'PRD2'
// Fall back on ID if no alias is set
function byAlias(relayA, relayB) {
    const a = relayA.alias || relayA.id;
    const b = relayB.alias || relayB.id;
    const reA = /[^a-zA-Z]/g;
    const reN = /[^0-9]/g;
    const aA = a.replace(reA, "");
    const bA = b.replace(reA, "");
    if (aA === bA) {
        const aN = parseInt(a.replace(reN, ""), 10);
        const bN = parseInt(b.replace(reN, ""), 10);
        return aN === bN ? 0 : aN > bN ? 1 : -1;
    } else {
        return aA > bA ? 1 : -1;
    }
}

const Relay = {
    list: [],
    activeList: [],
    current: null,
    loadRelays: () => {
        return m
            .request({
                method: "GET",
                url: "/relay",
                withCredentials: true,
            })
            .then(res => {
                Relay.list = res.sort(byAlias);
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    console.log(`Error in GET /relay  : ${e.message}`);
                }
            });
    },
    loadActiveRelays: () => {
        return m
            .request({
                method: "GET",
                url: "/relay/active",
                withCredentials: true,
            })
            .then(res => {
                Relay.activeList = res.sort(byAlias);
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    console.log(`Error in GET /relay  : ${e.message}`);
                }
            });
    },
};

export default Relay;
