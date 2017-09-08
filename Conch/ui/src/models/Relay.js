import m from "mithril";


// Use a natural sort with devices that end with a number.
// e.g, 'PRD10' comes after 'PRD2'
function byAlias(a,b) {
    const reA = /[^a-zA-Z]/g;
    const reN = /[^0-9]/g;
    const aA = a.alias.replace(reA, "");
    const bA = b.alias.replace(reA, "");
    if(aA === bA) {
        var aN = parseInt(a.alias.replace(reN, ""), 10);
        var bN = parseInt(b.alias.replace(reN, ""), 10);
        return aN === bN ? 0 : aN > bN ? 1 : -1;
    }
    else {
        return aA > bA ? 1 : -1;
    }
}

const Relay = {
    list : [],
    activeList : [],
    current : null,
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
