


#################### MODULES DEFINITION #################################
module_Not_a_numeric <- function(input, output, session, n) {
    output$msg_not_numeric <- renderUI({
        n()
        if (is.na(as.numeric(n()))) {
            tags$p("Please choose a number")
        }
    })
}



moduleDesignExample <- function(input, output, session, n) {
    output$nlevelsExample <- renderRHandsontable({
        if (n == 2) {
            df <- data.frame(
                Sample.name = paste0("Sample ", as.character(1:14)),
                Condition = c(rep("A", 4), rep("B", 4), rep("C", 6)),
                Bio.Rep = as.integer(
                    c(1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7)
                ),
                Tech.Rep = c(1:14),
                stringsAsFactors = FALSE
            )

            pal <- DAPAR::ExtendPalette(3, listBrewerPalettes[1])
            color_rend <- paste0("function (instance, td, row, col, prop, value,
      cellProperties) {
      Handsontable.renderers.TextRenderer.apply(this, arguments);
      if(col==1 && (row>=0 && row<=3)) {td.style.background = '", pal[1], "';}
      if(col==1 && (row>=4 && row<=7)) {td.style.background = '", pal[2], "';}
      if(col==1 && (row>=8 && row<=14)) {td.style.background = '", pal[3], "';}
      if(col==2 && (row %in% c(0, 1, 4, 5, 8, 9, 12, 13)))
      {td.style.background = 'lightgrey';}
      if(col==3 && (row %in% c(0, 2, 4, 6, 8, 10, 12)))
      {td.style.background = 'lightgrey';}
                    }")
        } else if (n == 3) {
            df <- data.frame(
                Sample.name = paste0("Sample ", as.character(1:16)),
                Condition = c(rep("A", 8), rep("B", 8)),
                Bio.Rep = as.integer(
                    c(rep(1, 4), rep(2, 4), rep(3, 4), rep(4, 4))
                ),
                Tech.Rep = as.integer(
                    c(1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8)
                ),
                Analyt.Rep = c(1:16),
                stringsAsFactors = FALSE
            )


            pal <- DAPAR::ExtendPalette(3, listBrewerPalettes[1])

            color_rend <- paste0(
                "function (instance,
                td, row, col, prop, value, cellProperties) {
                Handsontable.renderers.TextRenderer.apply(this, arguments);
                if(col==1 && (row>=0 && row<=7)) {td.style.background = '",
                pal[1], "';}
                if(col==1 && (row>=8 && row<=15))  {
                td.style.background = '", pal[2], "';}

                if(col==2 && (row %in% c(0, 1, 2, 3, 8, 9, 10, 11)))
                {td.style.background = 'lightgrey';}

                if(col==3 && (row %in% c(0, 1, 4, 5, 8, 9, 12, 13)))
                {td.style.background = 'lightgrey';}

                if(col==4 && (row %in% c(0, 2, 4, 6, 8, 10, 12, 14)))
                {td.style.background = 'lightgrey';}
              }"
            )
        }

        rhandsontable::rhandsontable(df,
            rowHeaders = NULL,
            fillHandle = list(
                direction = "vertical",
                autoInsertRow = FALSE,
                maxRows = nrow(rv$hot)
            )
        ) %>%
            rhandsontable::hot_rows(rowHeights = 30) %>%
            rhandsontable::hot_context_menu(
                allowRowEdit = FALSE,
                allowColEdit = FALSE,
                allowInsertRow = FALSE,
                allowInsertColumn = FALSE,
                allowRemoveRow = FALSE,
                allowRemoveColumn = FALSE,
                autoInsertRow = FALSE
            ) %>%
            rhandsontable::hot_cols(readOnly = TRUE, renderer = color_rend)
    })
}





moduleDetQuantImpValues <- function(input, output, session, quant, factor) {
    output$detQuantValues_DT <- DT::renderDataTable(server = TRUE, {
        req(rv$current.obj, quant(), factor())

        values <- getQuantile4Imp(
          Biobase::exprs(rv$current.obj),
            quant() / 100, factor()
        )
        DT::datatable(as.data.frame(t(values$shiftedImpVal)),
            rownames = FALSE,
            options = list(
                initComplete = initComplete(),
                dom = "t",
                bLengthChange = FALSE
            )
        )
    })
}


#------------------------------------------------------------

moduleVolcanoplot <- function(input, output, session,
                              data,
                              comp,
                              tooltip) {
    ns <- session$ns


    output$quantiDT <- renderUI({
        req(input$eventPointClicked)

        if (DAPAR::GetTypeofData(rv$current.obj) == "protein") {
            if (is.null(DAPAR::GetMatAdj(rv$current.obj))) {
                shinyBS::bsCollapse(
                    id = ns("collapseVolcanoInfos"),
                    open = "Protein",
                    multiple = TRUE,
                    shinyBS::bsCollapsePanel("Protein",
                        tagList(
                            uiOutput(ns("Warning_Infos")),
                            DT::dataTableOutput(ns("Infos"))
                        ),
                        style = "info"
                    )
                )
            } else {
                shinyBS::bsCollapse(
                    id = ns("collapseVolcanoInfos"),
                    open = "Protein",
                    multiple = TRUE,
                    shinyBS::bsCollapsePanel("Protein",
                        tagList(
                            uiOutput(ns("Warning_Infos")),
                            DT::dataTableOutput(ns("Infos"))
                        ),
                        style = "info"
                    ),
                    shinyBS::bsCollapsePanel("Specific peptides",
                        tagList(
                            uiOutput(ns("Warning_specificPeptidesInfos")),
                            DT::dataTableOutput(ns("specificPeptidesInfos"))
                        ),
                        style = "primary"
                    ),
                    shinyBS::bsCollapsePanel("Shared peptides",
                        tagList(
                            uiOutput(ns("Warning_sharedPeptidesInfos")),
                            DT::dataTableOutput(ns("sharedPeptidesInfos"))
                        ),
                        style = "primary"
                    )
                )
            }
        } else if (GetTypeofData(rv$current.obj) == "peptide") {
            shinyBS::bsCollapse(
                id = ns("collapseVolcanoInfos"),
                open = "peptide",
                multiple = TRUE,
                shinyBS::bsCollapsePanel("Peptide",
                    tagList(
                        uiOutput(ns("Warning_Infos")),
                        DT::dataTableOutput(ns("Infos"))
                    ),
                    style = "info"
                )
            )
        }
    })


    output$nbSelectedItems <- renderUI({
        rv$widgets$anaDiff$th_pval
        rv$widgets$hypothesisTest$th_logFC
        rv$current.obj
        req(data()$logFC)
        req(data()$P_Value)
        data()


        m <- match.metacell(DAPAR::GetMetacell(rv$current.obj),
                            pattern = c("Missing", "Missing POV", "Missing MEC"),
                            level = "peptide"
                            )
        #req(length(which(m)) > 0)

        p <- data()
        upItemsPVal <- NULL
        upItemsLogFC <- NULL


        upItemsLogFC <- which(abs(p$logFC) >= as.numeric(
            rv$widgets$hypothesisTest$th_logFC
        ))
        upItemsPVal <- which(-log10(p$P_Value) >= as.numeric(
            rv$widgets$anaDiff$th_pval
        ))

        rv$nbTotalAnaDiff <- nrow(Biobase::exprs(rv$current.obj))
        rv$nbSelectedAnaDiff <- NULL
        t <- NULL

        if (!is.null(rv$widgets$anaDiff$th_pval) &&
            !is.null(rv$widgets$hypothesisTest$th_logFC)) {
            t <- intersect(upItemsPVal, upItemsLogFC)
        } else if (!is.null(rv$widgets$anaDiff$th_pval) &&
            is.null(rv$widgets$hypothesisTest$th_logFC)) {
            t <- upItemsPVal
        } else if (is.null(rv$widgets$anaDiff$th_pval) &&
            !is.null(rv$widgets$hypothesisTest$th_logFC)) {
            t <- upItemsLogFC
        }
        rv$nbSelectedAnaDiff <- length(t)

        
        ##
        ## Condition: A = C + D
        ##
        A <- rv$nbTotalAnaDiff
        B <- A - length(rv$resAnaDiff$pushed)
        C <- rv$nbSelectedAnaDiff
        D <- ( A - C)
        # 
        # txt <- paste("Total number of ", rv$typeOfDataset, "(s) = ", A , "<br>",
        #   "\t <em>Total remaining after push p-values = ", B , "</em><br>",
        #     paste("Number of selected ", rv$typeOfDataset, "(s) = ", C, sep=''),
        #     paste("Number of non selected ", rv$typeOfDataset, "(s) = ", D, sep = ''),
        #     sep = ""
        # )
        
        div(id="bloc_page",
          style = "background-color: lightgrey; width: 300px",
          p(paste("Total number of ", rv$typeOfDataset, "(s) = ", A, sep = '' )),
          tags$em(p(style = "padding:0 0 0 20px;", paste("Total remaining after push p-values = ", B, sep=''))),
          p(paste("Number of selected ", rv$typeOfDataset, "(s) = ", C, sep = '')),
          p(paste("Number of non selected ", rv$typeOfDataset, "(s) = ", D, sep = ''))
        )
        #HTML(txt)
    })


    GetSortingIndices <- reactive({
        req(comp())

        condition1 <- gsub("[()]", "", strsplit(comp(), "_vs_")[[1]][1])
        condition2 <- gsub("[()]", "", strsplit(comp(), "_vs_")[[1]][2])
        .ind <- (which(Biobase::pData(rv$current.obj)$Condition == condition1))
        if (length(grep("all", condition2)) == 0) {
            ind <- c(
                which(Biobase::pData(rv$current.obj)$Condition == condition1),
                which(Biobase::pData(rv$current.obj)$Condition == condition2)
            )
        } else {
            ind <- c(
                which(Biobase::pData(rv$current.obj)$Condition == condition1),
                c(1:nrow(Biobase::pData(rv$current.obj)))[-.ind]
            )
        }
        ind
    })

    GetBorderIndices <- reactive({
        conds <- (Biobase::pData(rv$current.obj)$Condition)[GetSortingIndices()]
        ## build index for border-formatting
        borders_index <- unlist(lapply(
            unique(conds),
            function(x) {
                which.max(x == conds)
            }
        ))
        borders_index
    })



    output$Warning_sharedPeptidesInfos <- renderUI({
        GetDataFor_sharedPeptidesInfos()
        if (nrow(GetDataFor_sharedPeptidesInfos()) > 153) {
            p(MSG_WARNING_SIZE_DT)
        }
    })




    GetDataFor_sharedPeptidesInfos <- reactive({
        req(comp())

        ind <- GetSortingIndices()
        borders_index <- GetBorderIndices()

        .ind <- last(grep(pattern = "peptide", names(rv$dataset)))
        prev.dataset <- rv$dataset[[names(rv$dataset)[.ind]]]

        prot <- GetExprsClickedProtein()
        prot.indice <- rownames(prot)

        data <- getDataForExprs(prev.dataset, rv$settings_nDigits)
        data <- data[, c(ind, (ind + ncol(data) / 2))]

        Xspec <- DAPAR::GetMatAdj(rv$current.obj)$matWithUniquePeptides
        Xshared <- DAPAR::GetMatAdj(rv$current.obj)$matWithSharedPeptides

        i <- which(colnames(Xspec) == prot.indice)
        specificPeptidesIndices <- which(Xspec[, i] == 1)
        allPeptidesIndices <- which(Xshared[, i] == 1)
        peptidesIndices <- setdiff(allPeptidesIndices, specificPeptidesIndices)
        data <- data[peptidesIndices, ]
        data
    })

    output$sharedPeptidesInfos <- DT::renderDataTable(server = TRUE, {
        data <- GetDataFor_sharedPeptidesInfos()
        c.tags <- BuildColorStyles(rv$current.obj)$tags
        c.colors <- BuildColorStyles(rv$current.obj)$colors

        dt <- DT::datatable(
            data,
            extensions = c("Scroller"),
            options = list(
                initComplete = initComplete(),
                dom = "frtip",
                blengthChange = FALSE,
                displayLength = 20,
                ordering = FALSE,
                server = FALSE,
                columnDefs = list(
                    list(
                        targets = c(((ncol(data) / 2) + 1):(ncol(data))),
                        visible = FALSE
                    )
                )
            )
        ) %>%
          DT::formatStyle(
                colnames(data)[1:(ncol(data) / 2)],
                colnames(data)[((ncol(data) / 2) + 1):(ncol(data))],
                backgroundColor = DT::styleEqual(c.tags, c.colors)
            ) %>%
          DT::formatStyle(borders_index, borderLeft = "3px solid #000000")

        dt
    })

    output$Warning_specificPeptidesInfos <- renderUI({
        GetDataFor_specificPeptidesInfos()
        if (nrow(GetDataFor_specificPeptidesInfos()) > 153) {
            p(MSG_WARNING_SIZE_DT)
        }
    })

    GetDataFor_specificPeptidesInfos <- reactive({
        req(comp())

        ind <- GetSortingIndices()
        borders_index <- GetBorderIndices()
        .ind <- last(grep(pattern = "peptide", names(rv$dataset)))
        prev.dataset <- rv$dataset[[names(rv$dataset)[.ind]]]

        prot <- GetExprsClickedProtein()
        prot.indice <- rownames(prot)

        data <- getDataForExprs(prev.dataset, rv$settings_nDigits)
        data <- data[, c(ind, (ind + ncol(data) / 2))]


        Xspec <- DAPAR::GetMatAdj(rv$current.obj)$matWithUniquePeptides

        i <- which(colnames(Xspec) == prot.indice)
        peptidesIndices <- which(Xspec[, i] == 1)
        data <- data[peptidesIndices, ]
        data
    })


    output$specificPeptidesInfos <- DT::renderDataTable(server = TRUE, {
        data <- GetDataFor_specificPeptidesInfos()
        c.tags <- BuildColorStyles(rv$current.obj)$tags
        c.colors <- BuildColorStyles(rv$current.obj)$colors

        dt <- DT::datatable(
            data,
            extensions = c("Scroller"),
            options = list(
                initComplete = initComplete(),
                dom = "frtip",
                blengthChange = FALSE,
                displayLength = 20,
                ordering = FALSE,
                columnDefs = list(
                    list(
                        targets = c(
                            ((ncol(data) / 2) + 1):(ncol(data))
                        ),
                        visible = FALSE
                    )
                )
            )
        ) %>%
          DT::formatStyle(
                colnames(data)[1:(ncol(data) / 2)],
                colnames(data)[((ncol(data) / 2) + 1):(ncol(data))],
                backgroundColor = DT::styleEqual(c.tags, c.colors)
            ) %>%
          DT::formatStyle(borders_index, borderLeft = "3px solid #000000")

        dt
    })


    ## ---------------------------------------------------------
    GetExprsClickedProtein <- reactive({
        req(rv$current.obj)
        req(comp() != "None")
        req(input$eventPointClicked)
        rv$widgets$hypothesisTest$th_logFC
        rv$widgets$anaDiff$th_pval
        data()

        ind <- GetSortingIndices()
        # browser()
        this.index <- as.integer(strsplit(input$eventPointClicked, "_")[[1]][1])
        this.series.name <- strsplit(input$eventPointClicked, "_")[[1]][2]

        data <- getDataForExprs(rv$current.obj, rv$settings_nDigits)
        data <- data[, c(ind, (ind + ncol(data) / 2))]

        .thlogfc <- rv$widgets$hypothesisTest$th_logFC
        index.g1 <- which((-log10(data()$P_Value) >= rv$widgets$anaDiff$th_pval
        ) & (abs(data()$logFC) >= as.numeric(.thlogfc)))

        data.g1 <- data[index.g1, ]
        data.g2 <- data[-index.g1, ]

        switch(this.series.name,
            g1 = data <- data.g1[this.index + 1, ],
            g2 = data <- data.g2[this.index + 1, ]
        )
        data
    })



    output$Warning_Infos <- renderUI({
        GetDataFor_Infos()
        if (nrow(GetDataFor_Infos()) > 153) {
            p(MSG_WARNING_SIZE_DT)
        }
    })




    GetDataFor_Infos <- reactive({
        req(comp())
        data <- GetExprsClickedProtein()
        data
    })

    ## -------------------------------------------------------------
    output$Infos <- DT::renderDataTable(server = TRUE, {
        req(comp())

        borders_index <- GetBorderIndices()
        data <- GetExprsClickedProtein()
        c.tags <- BuildColorStyles(rv$current.obj)$tags
        c.colors <- BuildColorStyles(rv$current.obj)$colors

        dt <- DT::datatable(
            data,
            extensions = c("Scroller"),
            options = list(
                initComplete = initComplete(),
                dom = "frtip",
                blengthChange = FALSE,
                displayLength = 20,
                ordering = FALSE,
                header = FALSE,
                columnDefs = list(
                    list(
                        targets = c(((ncol(data) / 2) + 1):(ncol(data))),
                        visible = FALSE
                    )
                )
            )
        ) %>%
          DT::formatStyle(
                colnames(data)[1:(ncol(data) / 2)],
                colnames(data)[((ncol(data) / 2) + 1):(ncol(data))],
                backgroundColor = DT::styleEqual(c.tags, c.colors)
            ) %>%
          DT::formatStyle(borders_index, borderLeft = "3px solid #000000")



        dt
    })

    ## ---------------------------------------------------------------------
    output$volcanoPlot <- renderHighchart({
        rv$widgets$anaDiff$th_pval
        rv$widgets$hypothesisTest$th_logFC
        rv$colorsVolcanoplot
        data()$P_Value
        req(length(data()$logFC) > 0)
        tooltip()

        # browser()
        isolate({
            withProgress(message = "Building plot...", detail = "", value = 0, {
                m <- match.metacell(DAPAR::GetMetacell(rv$current.obj),
                                    pattern = c("Missing", "Missing POV", "Missing MEC"),
                                    level = DAPAR::GetTypeofData(rv$current.obj)
                                    )
                if (length(which(m)) > 0) {
                    return(NULL)
                }
                df <- data.frame(
                    x = data()$logFC,
                    y = -log10(data()$P_Value),
                    index = 1:nrow(Biobase::fData(rv$current.obj))
                )
                if (length(tooltip()) > 0 && !is.na(tooltip())) {
                    df <- cbind(
                        df,
                      Biobase::fData(rv$current.obj)[tooltip()]
                    )
                }

                colnames(df) <- gsub(".", "_", colnames(df), fixed = TRUE)
                if (ncol(df) > 3) {
                    colnames(df)[4:ncol(df)] <-
                        paste("tooltip_", colnames(df)[4:ncol(df)], sep = "")
                }

                clickFun <-
                    JS(paste0(
                        "function(event) {Shiny.onInputChange('",
                        ns("eventPointClicked"),
                        "', [this.index]+'_'+ [this.series.name]);}"
                    ))

                cond <- c(data()$condition1, data()$condition2)
                rv$tempplot$volcano <- diffAnaVolcanoplot_rCharts(
                    df,
                    threshold_logFC = as.numeric(
                        rv$widgets$hypothesisTest$th_logFC
                    ),
                    threshold_pVal = as.numeric(rv$widgets$anaDiff$th_pval),
                    conditions = cond,
                    clickFunction = clickFun,
                    pal = rv$colorsVolcanoplot
                )
            })

            rv$tempplot$volcano
        })
    })
}


#------------------------------------------------------------
moduleDensityplot <- function(input, output, session, data) {
    output$Densityplot <- renderHighchart({
        data()
        rv$PlotParams$paletteForConditions
        rv$PlotParams$legendForSamples
        tmp <- NULL
         isolate({
            withProgress(message = "Making plot", value = 100, {
                pattern <- paste0(GetCurrentObjName(), ".densityplot")
                tmp <- DAPAR::densityPlotD_HC(data(),
                    legend = rv$PlotParams$legendForSamples,
                    pal = unique(rv$PlotParams$paletteForConditions)
                )
                future(createPNGFromWidget(rv$tempplot$boxplot, pattern))
            })
        })
        tmp
    })
}


#------------------------------------------------------------
moduleBoxplot <- function(input, output, session, data, pal) {
    observeEvent(input$choosePlot, {
        switch(input$choosePlot,
            boxplot = {
                shinyjs::hide("viewViolinPlot")
                shinyjs::show("BoxPlot")
            },
            violinplot = {
                shinyjs::hide("BoxPlot")
                shinyjs::show("viewViolinPlot")
            }
        )
    })


    output$BoxPlot <- renderHighchart({
        # req(rv$current.obj)
        data()
        rv$current.obj.name
        rv$PlotParams$paletteForConditions
        rv$PlotParams$legendForSamples

        tmp <- NULL
        isolate({
            pattern <- paste0(GetCurrentObjName(), ".boxplot")
            tmp <- DAPAR::boxPlotD_HC(data(),
                conds = Biobase::pData(data())$Condition,
                legend = rv$PlotParams$legendForSamples,
                pal = pal()
            )
            # future(createPNGFromWidget(tmp,pattern))
        })
        tmp
    })

    output$viewViolinPlot <- renderImage(
        {
          if (!requireNamespace("grDevices", quietly = TRUE)) {
            stop("Please install grDevices: BiocManager::install('grDevices')")
          }
          # req(rv$current.obj)
            data()
            rv$PlotParams$legendForSamples
            rv$PlotParams$paletteForConditions
            tmp <- NULL

            isolate({

                # A temp file to save the output. It will be deleted after
                # renderImage
                # sends it, because deleteFile=TRUE.
                outfile <- tempfile(fileext = ".png")

                # Generate a png
                # png(outfile, width = 640, height = 480, units = "px")
                grDevices::png(outfile)
                pattern <- paste0(GetCurrentObjName(), ".violinplot")
                tmp <- DAPAR::violinPlotD(data(),
                    conds = Biobase::pData(data())$Condition,
                    legend = rv$PlotParams$legendForSamples,
                    pal = pal()
                )
                # future(createPNGFromWidget(tmp,pattern))
                dev.off()
            })
            # Return a list
            list(
                src = outfile,
                alt = "This is alternate text"
            )
        },
        deleteFile = TRUE
    )
}



moduleMVPlots <- function(input, output, session, data, title, pal, pattern) {
    output$plot_viewNAbyMean <- renderHighchart({
        req(data())

        #browser()
        hc_mvTypePlot2( obj = data(),
                        pattern = pattern,
                        title = title(),
                        pal = pal()
                        )
    })




    output$WarnForImageNA <- renderUI({
        tryCatch(
            {
                wrapper.mvImage(data())
            },
            warning = function(w) {
                p(conditionMessage(w))
            },
            error = function(e) {
                p(conditionMessage(e))
            },
            finally = {
                # cleanup-code
            }
        )
    })

    output$plot_showImageNA <- renderImage(
        {
            # req(wrapper.mvImage(data()))

            # A temp file to save the output. It will be deleted after
            # renderImage
            # sends it, because deleteFile=TRUE.
            outfile <- tempfile(fileext = ".png")

            png(outfile)
            wrapper.mvImage(data())
            dev.off()

            # Return a list
            list(
                src = outfile,
                alt = "This is alternate text"
            )
        },
        deleteFile = TRUE
    )
}


moduleFilterStringbasedOptions <- function(input, output, session) {
    output$FilterStringbasedOptions <- renderUI({
        rv$current.obj
        if (is.null(rv$current.obj)) {
            return()
        }

        tagList(
            h4("String based filtering options"),
            hr(),
            h4("Filter contaminants"),
            uiOutput("id_Contaminants"),
            uiOutput("choosePrefixContaminants"),
            br(),
            h4("Filter reverse"),
            uiOutput("id_Reverse"),
            uiOutput("choosePrefixReverse"),
            br(),
            # actionButton("resetFilterParamsButton","Reset parameters"),
            actionButton("performFilteringContaminants",
                "Perform string-based filtering",
                class = actionBtnClass
            )
        )
    })
}







# moduleInsertMarkdown <- function(input, output, session, url) {
#     ns <- session$ns
#     output$insertMD <- renderUI({
#         #print(url)
#         tryCatch(
#             {
#                 includeMarkdown(url)
#             },
#             warning = function(w) {
#                 # conditionMessage(w)
#                 tags$p("URL not found. Please check your internet connection.")
#             },
#             error = function(e) {
#                 shinyjs::info(paste("Error :", "in moduleInsertMarkdown", ":",
#                     conditionMessage(e),
#                     sep = " "
#                 ))
#             },
#             finally = {
#                 # cleanup-code
#             }
#         )
#     })
# }
