var m = require("mithril");

var Rack = {
    list: [],
    loadList: function() {
        return m.request({
            method: "GET",
            url: "http://10.64.223.75:80/rack",
            headers: {
                "Access-Control-Allow-Credentials": true
            },
            withCredentials: true
        }).then(function(result) {
            console.log("Result is...");
            console.log(result);
            Rack.list = result.data.racks;
        });
    },

    current: {},
    load: function(id) {
        return m.request({
            method: "GET",
            url: "http://10.64.223.75:80/rack/" + id,
            withCredentials: true
        }).then(function(result) {
            Rack.current = result;
        });
    }
}

module.exports = Rack;
