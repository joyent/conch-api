import m from "mithril";

function byAlias(a,b) {
    if (a.alias < b.alias) {
        return -1;
    }
    if (a.alias > b.alias) {
        return 1;
    }
    return 0;
}

const Relay = {
    list : [],
    activeList : [],
    current : null,
    loadCurrentRelay : () => {
    },
    loadRelays : () => {
        return m.request({
            method: "GET",
            url: "/relay",
            withCredentials: true
        }).then(function(res) {
            Relay.list = res.sort(byAlias);
        }).catch(function(e) {
            if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
                console.log("Error in GET /relay  : " + e.message);
            }
        });
    },
    loadActiveRelays : () => {
        return m.request({
            method: "GET",
            url: "/relay/active",
            withCredentials: true
        }).then(function(res) {
            Relay.activeList = res.sort(byAlias);
        }).catch(function(e) {
            if (e.error === "unauthorized") {
                m.route.set("/login");
            }
            else {
                console.log("Error in GET /relay  : " + e.message);
            }
        });
    },
};

module.exports = Relay;
