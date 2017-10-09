import m from "mithril";

/* Function to create a table. Takes a table caption string, list of string headers, and a list of
 * lists of elements for the data rows.  The table use with data-labels that are
 * used to collapse the table for smaller screens. The number of elements in
 * the header much match the number of elements in each list of the rows. */
function table(caption, header, rows) {
    return m(
        ".pure-u-1",
        m("table.pure-table.pure-table-striped", [
            m("caption", caption),
            m("thead", m("tr", header.map(h => m("th", h)))),
            m(
                "tbody",
                rows.map(r =>
                    m(
                        "tr",
                        r.map((d, i) => m("td", { "data-label": header[i] }, d))
                    )
                )
            ),
        ])
    );
}

export default table;
