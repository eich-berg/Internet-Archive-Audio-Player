import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn layout(elements: List(Element(t))) -> Element(t) {
  html.html([], [
    html.head([], [
      html.title([], "♪♫•*¨*•.¸¸Internet Archive Audio Player¸¸.•*¨*•♫♪"),
      html.meta([
        attribute.name("viewport"),
        attribute.attribute("content", "width=device-width, initial-scale=1"),
      ]),
      html.link([
        attribute.rel("icon"),
        attribute.type_("image/x-icon"),
        attribute.href("/static/favicon.ico"),
      ]),
      html.link([
      attribute.rel("stylesheet"),
      attribute.href("/static/app.css")]),
    ]),
    html.body([], elements),
  ])
}