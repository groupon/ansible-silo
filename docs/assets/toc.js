$(function() {
    var toc = $("#toc")
    var tocTop = toc.offset().top;
    tocbot.init({
        tocSelector: "#toc",
        contentSelector: "#content",
        headingSelector: "h2, h3, h4, h5, h6",
        positionFixedSelector: "#toc",
        fixedSidebarOffset: tocTop - 20,
        activeLinkClass: "active",
        smoothScroll: false
    });

    function set_bottom_margin() {
        var last_headline = $('h1,h2,h3,h4,h5,h5').last();
        var current_margin = $("#bottom_spacer").offset().top - last_headline.offset().top;
        var viewport_height = $(window).height();
        var margin_needed = Math.max(0, viewport_height - current_margin - 30);
        $("#bottom_spacer").height(margin_needed);
    }
    set_bottom_margin();
    $(window).resize(function() {
        set_bottom_margin()
    });
});
