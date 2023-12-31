tabPanel(
    title = "Global settings",
    value = "GlobalSettingsTab",
    tabsetPanel(
        tabPanel(
            "Miscellaneous",
            div(
                div(
                    style = "display:inline-block; vertical-align: middle;
          padding-right: 20px;",
                    popover_for_help_ui("modulePopover_numPrecision")
                ),
                div(
                    style = "display:inline-block; vertical-align: middle;",
                    uiOutput("settings_nDigits_UI")
                )
            ),
            tags$br(), tags$hr(),
            tags$p(style = "font-size: 18px;", tags$b("Figure export options")),
            tagList(
                tags$div(
                    style = "display:inline-block; vertical-align: middle;
             padding-right: 40px;",
                    selectInput("sizePNGplots", "Size of images (PNG)",
                        choices = c("1200 * 800"), width = "150px"
                    )
                ),
                tags$div(
                    style = "display:inline-block; vertical-align: middle;
             padding-right: 40px;",
                    selectInput("resoPNGplots", "Resolution",
                        choices = c(150), width = "100px"
                    )
                )
            )
        ),
        tabPanel(
            "Colors",
            div(
                id = "showInfoColorOptions",
                tags$p("Color customization is available after data
                      loading only.")
            ),
            hidden(uiOutput("defineColorsUI"))
        )
    )
)
