
library(shiny)
library(shinyjs)
library(shinyBS)
#library(rclipboard)
library(sass)
source(file.path("ui", "ui_Configure.R"), local = TRUE)$value
source(file.path(".", "modules/Plots/modulePlots.R"), local = TRUE)$value
source(file.path("server", "mod_popover_for_help.R"), local = TRUE)$value
#source(file.path("server", "mod_popover.R"), local = TRUE)$value
source(file.path("server", "mod_download_btns.R"), local = TRUE)$value
source(file.path("modules/Plots", "mod_MSnSetExplorer.R"), local = TRUE)$value
source(file.path("server", "mod_LegendColoredExprs.R"), local = TRUE)$value
source(file.path("server", "mod_format_DT.R"), local = TRUE)$value
source(file.path("server", "mod_dl.R"), local = TRUE)$value

theme <- shinythemes::shinytheme(theme = "cerulean")
#---------------------------------------------------------------------
jsResetCode <- "shinyjs.resetProstar = function() {history.go(0)}"

shinyUI(
    fluidPage(
        if (!requireNamespace("rclipboard", quietly = TRUE)) {
            stop("Please install rclipboard: BiocManager::install('rclipboard')")
        },
        
        rclipboard::rclipboardSetup(),
        
        #tags$head(includeHTML(("www/google-analytics.html"))),
        
        
    if (!requireNamespace("sass", quietly = TRUE)) {
        stop("Please install sass: BiocManager::install('sass')")
    },
    
    
     #theme = "css/ceruleanProstar.css",
     theme = shinythemes::shinytheme(theme = "cerulean"),
    tagList(
        shinyjs::useShinyjs(),
        extendShinyjs(text = jsResetCode, functions = c("resetProstar")),
        includeCSS("www/progressBar/progressBar.css"),
        tags$head(tags$style(sass::sass(
           sass::sass_file("www/css/sass-size.scss"),
           sass::sass_options(output_style = "expanded")
        ))),
        titlePanel("", windowTitle = "Prostar"),

        ###### DIV LOADING PAGE  #######
         div(
             id = "loading_page",
             absolutePanel(
                id = "AbsolutePanel",
                class = "panel panel-default",
                style = "text-align: center; background-color: #25949A;",
                top = "30%",
                left = "25%",
                width = "50%",
                height = "150px",
                draggable = FALSE,
                fixed = TRUE,
                tagList(
                    tags$h1(
                        style = "text-align: center; color: white",
                        "Prostar is loading, please wait..."
                    ),
                    br(),
                    tags$div(
                        class = "progress",
                        tags$div(class = "indeterminate")
                    )
                )
            )

        ),

        ###### DIV MAIN CONTENT  #######
        hidden(
            div(
                id = "main_content",
                tags$head(includeCSS("www/css/arrow.css")),
                launchGA(),
                tags$head(
                    HTML(
                        "<script type='text/javascript' src='sbs/shinyBS.js'></script>")
                ),
                tags$head(tags$style(".modal-dialog{ width:200px}")),
                tags$head(
                    tags$style( HTML("hr {border-top: 1px solid #000000;}"))),
                tags$style(HTML(".tab-content {padding-top: 40px; }")),
                sidebarPanelWidth(),
                includeCSS("www/css/prostar.css"),
                inlineCSS(".body { font-size:14px;}"),
                inlineCSS(".rect {float: left;
                  width: 100px;
                  height: 20px;
                  margin: 2px;
                  border: 1px solid rgba(0, 0, 0, .2);}"),
                inlineCSS(".green {background: #06AB27}"),
                inlineCSS(".red {background: #C90404}"),
                inlineCSS(".grey {background:lightgrey;}"),
                div(
                    id = "header",
                    navbarPage(
                        position = "fixed-top",
                        id = "navPage",
                        inverse = TRUE,
                        absolutePanel(
                            id = "#AbsolutePanel",
                            top = 0,
                            right = 50,
                            width = "500px",
                            height = "50px",
                            draggable = FALSE,
                            fixed = FALSE,
                            cursor = "default",
                            uiOutput("datasetAbsPanel")
                        ),
                        navbarMenu(
                            "Prostar",
                            source(file.path("ui", "ui_Home.R"),
                                local = TRUE
                            )$value,
                            source(file.path("ui", "ui_Settings.R"),
                                local = TRUE
                            )$value,
                            source(file.path("ui", "ui_ReleaseNotes.R"), local = TRUE)$value,
                            source(file.path("ui", "ui_CheckForUpdates.R"),
                                local = TRUE
                            )$value
                        ),
                        navbarMenu(
                            "Data manager",
                            source(file.path("ui", "ui_OpenMSnSetFile.R"), local = TRUE)$value,
                            source(file.path("ui", "ui_ConvertData.R"), local = TRUE)$value,
                            source(file.path("ui", "ui_DemoMode.R"), local = TRUE)$value,
                            source(file.path("ui", "ui_Export.R"), local = TRUE)$value,
                            source(file.path("ui", "ui_ReloadProstar.R"), local = TRUE)$value
                        ),
                        navbarMenu(
                            "Help",
                            source(file.path("ui", "ui_UsefulLinks.R"), local = TRUE)$value,
                            source(file.path("ui", "ui_FAQ.R"), local = TRUE)$value,
                            source(file.path("ui", "ui_BugReport.R"), local = TRUE)$value
                        )
                    ) ## end navbarPage
                ) ## end div for main content 2
            #) ## end div for main content 1
        )
        )
    )
) ## end fluid
)