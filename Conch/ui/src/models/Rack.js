var m = require("mithril");

var Rack = {
    list: [],
    loadList: function() {
        return m.request({
            method: "GET",
            url: "http://localhost:5000/rack",
            withCredentials: true
        }).then(function(result) {
            console.log("Result is...");
            console.log(result);
            Rack.list = result.data.racks;
        }).catch(function(e) {
            console.log("Error in GET /rack: " + e.message);
        });
    },

    current: {},
    load: function(id) {
        return m.request({
            method: "GET",
            url: "http://localhost:5000/rack/" + id,
            withCredentials: true
        }).then(function(result) {
            Rack.current = result;
        }).catch(function(e) {
            console.log("Error in GET /rack/" + id + ": " + e.message);
        });
    }
}

module.exports = Rack;
