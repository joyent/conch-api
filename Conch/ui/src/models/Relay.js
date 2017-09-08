import m from "mithril";

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
            Relay.list = res;
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
            Relay.activeList = res;
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
