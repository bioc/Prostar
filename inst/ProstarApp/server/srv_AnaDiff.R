callModule(moduleVolcanoplot,"volcano_Step1", reactive({input$selectComparison}),reactive({input$tooltipInfo}))
callModule(moduleVolcanoplot,"volcano_Step2",reactive({input$selectComparison}),reactive({input$tooltipInfo}))



output$anaDiffPanel <- renderUI({
  req(rv$current.obj)
  NA.count<- length(which(is.na(Biobase::exprs(rv$current.obj))))
  if (NA.count > 0){
    tags$p("Your dataset contains missing values. Before using the differential analysis, you must filter/impute them")
  } else if (is.null(rv$current.obj@experimentData@other$Params$anaDiff)) {
    tags$p("The statistical test has not been performed so the differential analysis cannot be done.")
    } else {
  tabsetPanel(
    id = "xxx",
    
    tabPanel("2 - Pairwise comparison",
             value = "DiffAnalysis_PairewiseComparison",
             sidebarCustom(),
             splitLayout(cellWidths = c(widthLeftPanel, widthRightPanel),
                         wellPanel(
                           id = "sidebar_DiffAna2",
                           height = "100%"
                           ,uiOutput("newComparisonUI")
                           ,uiOutput("diffAnalysis_PairwiseComp_SB")
                           ,actionButton("AnaDiff_perform.filtering.MV", "Perform"),
                           uiOutput("tooltipInfo")
                         ),
                         tagList(
                            moduleVolcanoplotUI("volcano_Step1") %>% withSpinner(type=spinnerType)
                         )
             )
    ),
    tabPanel("3 - p-value calibration",
             value = "DiffAnalysis_Calibrate",
             sidebarCustom(),
             splitLayout(cellWidths = c(widthLeftPanel, widthRightPanel),
                         wellPanel(
                           id = "sidebar_DiffAna3",
                           height = "100%"
                           #,h4("Calibration")
                           ,uiOutput("diffAnalysis_Calibration_SB")
                         ),
                         tagList(
                           htmlOutput("errMsgCalibrationPlotAll"),
                           plotOutput("calibrationPlotAll") %>% withSpinner(type=spinnerType),
                           uiOutput("errMsgCalibrationPlot"),
                           plotOutput("calibrationPlot") %>% withSpinner(type=spinnerType)
                         )
             )
    ),
    tabPanel("4 - FDR",
             value = "DiffAnalysis_viewFDR",
             sidebarCustom(),
             splitLayout(cellWidths = c(widthLeftPanel, widthRightPanel),
                         wellPanel(id = "sidebar_DiffAna4",
                                   height = "100%"
                                   #,h4("Compute FDR")
                                   ,uiOutput("diffAnalysis_FDR_SB"),
                                   checkboxInput("showpvalTable","Show p-value table", value=FALSE)
                         ),
                         
                         tagList(
                           fluidRow(
                             column(width= 4, htmlOutput("equivPVal")),
                             column(width= 4, htmlOutput("showFDR"))
                           ),
                           hr(),
                           moduleVolcanoplotUI("volcano_Step2") %>% withSpinner(type=spinnerType),
                           DT::dataTableOutput("showSelectedItems", width='800px')
                         )
             )
    ), # end tabPanel(title = "3 - Visualize FDR"
    tabPanel("5 - Validate & save",
             value = "DiffAnalysis_ValidateAndSave",
             #sidebarCustom(),
             tagList(
                     dataTableOutput("resumeParams"),
                     actionButton("ValidDiffAna","Save diff analysis"),
                     uiOutput("DiffAnalysisSaved")
             )
    ) # end tabPanel(title = "4 - Validate and Save", 
  ) # end tabsetPanel
}
})



output$resumeParams <- DT::renderDataTable({
  req(c(rv$current.obj,input$selectComparison,
        rv$seuilPVal,input$AnaDiff_ChooseFilters,input$calibrationMethod))
   rv$resAnaDiff
  req(rv$res_AllPairwiseComparisons)
  
  #if ((input$ValidDiffAna == 0)) { return()}
  if (length(which(is.na(Biobase::exprs(rv$current.obj)))) > 0) { return()}
  
  
  #if (! (is.null(rv$resAnaDiff$logFC))  ){  
    
    l.params <- data.frame(param="comp", value=input$selectComparison)
    
    l.params <- rbind(l.params,data.frame(param="swapVolcano", value=as.character(input$swapVolcano)))
    l.params <- rbind(l.params,data.frame(param="filterType", value=input$AnaDiff_ChooseFilters))
    
    if( !is.null(input$AnaDiff_seuilNA)) {
        l.params <- rbind(l.params,data.frame(param="filter_th_NA", value=as.character(input$AnaDiff_seuilNA)))
    }
    
    l.params <- rbind(l.params,data.frame(param="calibMethod", value=input$calibrationMethod)) 
    if (input$calibrationMethod == "numeric value"){
      l.params <- rbind(l.params,data.frame(param="numValCalibMethod", value=as.character(input$numericValCalibration)))}
     
    l.params <- rbind(l.params,data.frame(param="th_pval", value=as.character(rv$seuilPVal)))
    
    # l.params[["fdr"]] <- diffAnaComputeFDR(rv$resAnaDiff[["logFC"]], 
    #                                        rv$resAnaDiff[["P_Value"]],
    #                                        rv$seuilPVal, 
    #                                        rv$seuilLogFC,
    #                                        m)
    
  
  DT::datatable(l.params,
                escape = FALSE,
                rownames=FALSE,
                extensions = 'Buttons',
                options = list(initComplete = initComplete(),
                               dom = 'Bfrtip',
                               buttons = c('copy','excel', 'pdf', 'print'),
                               columnDefs = list(list(width='200px',targets= "_all")))
  )
  #}
})




output$warningNA <- renderUI({
    rv$current.obj
    if (is.null(rv$current.obj)) {return ()}
    
    NA.count <- length(which(is.na(Biobase::exprs((rv$current.obj)))))
    
    if(NA.count    >    0){
        
        text <- "<br> <br> <font color=\"red\">
        Warning ! Your dataset contains empty lines so that the 
        imputation cannot be proceed.
        <br> <br> Please filter your data first."
        HTML(text)
    }
})



callModule(modulePopover,"modulePopover_volcanoTooltip", 
           data = reactive(list(title = HTML(paste0("<strong><font size=\"4\">Tooltip</font></strong>")), 
                                content="Infos to be displayed in the tooltip of volcanoplot")))

callModule(modulePopover,"modulePopover_pushPVal", data = reactive(list(title=HTML(paste0("<strong><font size=\"4\">P-Value push</font></strong>")),
                                                                        content= "This functionality is useful in case of multiple pairwise omparisons (more than 2 conditions): At the filtering step, a given analyte X (either peptide or protein) may have been kept because it contains very few missing values in a given condition (say Cond. A), even though it contains (too) many of them in all other conditions (say Cond B and C only contains “MEC” type missing values). Thanks to the imputation step, these missing values are no longer an issue for the differential analysis, at least from the computational viewpoint. However, statistically speaking, when performing B vs C, the test will rely on too many imputed missing values to derive a meaningful p-value: It may be wiser to consider analyte X as non-differentially abundant, regardless the test result (and thus, to push its p-value to 1). This is just the role of the “P-value push” parameter. It makes it possible to introduce a new filtering step that only applies to each pairwise comparison, and which assigns a p-value of 1 to analytes that, for the considered comparison are assumed meaningless due to too many missing values (before imputation).")))



output$newComparisonUI <- renderUI({
  rv$current.obj
  
  if (is.null(rv$current.obj)){ return()}
  
  if ("Significant" %in% colnames(Biobase::fData(rv$current.obj))){
    
      actionButton("newComparison", "New comparison")
  }
  
})


observeEvent(input$newComparison, {
    
    updateSelectInput(session,"selectComparison", selected="None")
    updateCheckboxInput(session,"swapVolcano", value=FALSE )
    updateRadioButtons(session, "AnaDiff_ChooseFilters", selected=gFilterNone)
    
    updateSelectInput(session,"calibrationMethod", selected="pounds")
    updateNumericInput(session, "seuilPVal", value=0)
    
    
})






output$AnaDiff_seuilNADelete <- renderUI({ 
    input$AnaDiff_ChooseFilters
  rv$current.obj
    if (is.null(rv$current.obj)) {return(NULL)   }
    if (input$AnaDiff_ChooseFilters==gFilterNone) {return(NULL)   }
    
    choix <- getListNbValuesInLines(rv$current.obj, type=input$AnaDiff_ChooseFilters)
   
    selectInput("AnaDiff_seuilNA", 
                "Keep lines with at least x intensity values", 
                choices = choix)
    
})


observeEvent(input$swapVolcano,{
    req(rv$resAnaDiff)
    rv$resAnaDiff$FC <- - (rv$resAnaDiff$logFC)
})


#####
####  SELECT AND LOAD ONE PARIWISE COMPARISON
####
observeEvent(input$selectComparison,{
  req(rv$res_AllPairwiseComparisons)
  
if (input$selectComparison== "None"){
    rv$resAnaDiff <- NULL
} else {
    #if (is.null(rv$current.obj@experimentData@other$Params[["anaDiff"]])) {  ### There is no previous analysis
        index <- which(paste(input$selectComparison, "_logFC", sep="") == colnames(rv$res_AllPairwiseComparisons$logFC))
        rv$resAnaDiff <- list(logFC = (rv$res_AllPairwiseComparisons$logFC)[,index],
                          P_Value = (rv$res_AllPairwiseComparisons$P_Value)[,index],
                          condition1 = strsplit(input$selectComparison, "_vs_")[[1]][1],
                          condition2 = strsplit(input$selectComparison, "_vs_")[[1]][2]
                        )
    
}
})





output$diffAnalysis_PairwiseComp_SB <- renderUI({
    req(rv$current.obj)
    req(rv$res_AllPairwiseComparisons)
    
    .choices <- unlist(strsplit(colnames(rv$res_AllPairwiseComparisons$logFC), "_logFC"))
    
    tagList(
        
        selectInput("selectComparison","Select comparison",choices = c("None",.choices)),
        
        checkboxInput("swapVolcano", "Swap volcanoplot", value = FALSE),
        br(),
        br(),
        
        modulePopoverUI("modulePopover_pushPVal"),
        
        radioButtons("AnaDiff_ChooseFilters","", choices = gFiltersListAnaDiff),
        
        uiOutput("AnaDiff_seuilNADelete")
    ) })



GetBackToCurrentResAnaDiff <- reactive({
  rv$res_AllPairwiseComparisons
  req(input$selectComparison)
  req(rv$res_AllPairwiseComparisons)
  
  index <- which(paste(input$selectComparison, "_logFC", sep="") == colnames(rv$res_AllPairwiseComparisons$logFC))
  rv$resAnaDiff <- list(logFC = (rv$res_AllPairwiseComparisons$logFC)[,index],
                        P_Value = (rv$res_AllPairwiseComparisons$P_Value)[,index],
                        condition1 = strsplit(input$selectComparison, "_vs_")[[1]][1],
                        condition2 = strsplit(input$selectComparison, "_vs_")[[1]][2]
  )
})


########################################################
## Perform missing values filtering
########################################################
observeEvent(input$AnaDiff_perform.filtering.MV,{
  input$selectComparison
   
if (input$AnaDiff_ChooseFilters == gFilterNone){
  GetBackToCurrentResAnaDiff()
} else {
  condition1 = strsplit(input$selectComparison, "_vs_")[[1]][1]
  condition2 = strsplit(input$selectComparison, "_vs_")[[1]][2]
  ind <- c( which(pData(rv$current.obj)$Condition==condition1), 
            which(pData(rv$current.obj)$Condition==condition2))
  datasetToAnalyze <- rv$dataset[[input$datasets]][,ind]
  datasetToAnalyze@experimentData@other$OriginOfValues <-
    rv$dataset[[input$datasets]]@experimentData@other$OriginOfValues[ind]
  
  keepThat <- mvFilterGetIndices(datasetToAnalyze,
                                 input$AnaDiff_ChooseFilters,
                                 as.integer(input$AnaDiff_seuilNA))
        if (!is.null(keepThat))
            {
            rv$resAnaDiff$P_Value[-keepThat] <- 1
            rv$resAnaDiff
            
            updateSelectInput(session, "AnaDiff_ChooseFilters", selected = input$AnaDiff_ChooseFilters)
            updateSelectInput(session, "AnaDiff_seuilNA", selected = input$AnaDiff_seuilNA)
                    
        }
    }
})






output$tooltipInfo <- renderUI({
  req(c(rv$current.obj,input$selectComparison))
   if (input$selectComparison=="None"){return()}
  
  tagList(
    hr(),
    modulePopoverUI("modulePopover_volcanoTooltip"),
    selectInput("tooltipInfo",
                label = "",
                choices = colnames(fData(rv$current.obj)),
                multiple = TRUE, selectize=FALSE,width='500px', size=5)
  )
  
})



output$diffAnalysis_Calibration_SB <- renderUI({
    req(rv$current.obj)
    
    #if (is.null(calibMethod)){ calibMethod <- "Benjamini-Hochberg"}
    
    tagList(
        selectInput("calibrationMethod", 
                    "Calibration method",
                    choices = calibMethod_Choices),
        uiOutput("numericalValForCalibrationPlot"))
})





output$diffAnalysis_FDR_SB <- renderUI({
    req(rv$current.obj)
    
    
        numericInput("seuilPVal", 
                     "Define the -log10(p_value) threshold",
                     min = 0,value = 0,step=0.1)
     })








#-------------------------------------------------------------
output$showFDR <- renderText({
    req(rv$current.obj)
    rv$seuilPVal
    rv$seuilLogFC
    input$numericValCalibration
    input$calibrationMethod
    req(rv$resAnaDiff)
    input$selectComparison
    
    if (is.null(input$selectComparison) || (input$selectComparison == "None")) 
    {return()}
    if (is.null(rv$seuilLogFC) ||is.na(rv$seuilLogFC)  ) 
    {return()}
    if (is.null(rv$seuilPVal) || is.na(rv$seuilPVal)) { return ()}
    if (length(which(is.na(Biobase::exprs(rv$current.obj)))) > 0) {return()}


                m <- NULL
                if (input$calibrationMethod == "Benjamini-Hochberg") { m <- 1}
                else if (input$calibrationMethod == "numeric value") {
                    m <- as.numeric(input$numericValCalibration)} 
                else {m <- input$calibrationMethod }
                
                rv$fdr <- diffAnaComputeFDR(rv$resAnaDiff[["logFC"]], 
                                            rv$resAnaDiff[["P_Value"]],
                                            rv$seuilPVal, 
                                            rv$seuilLogFC, 
                                            m)
                if (!is.infinite(rv$fdr)){
                    HTML(paste("<h4>FDR = ", 
                               round(100*rv$fdr, digits=2)," % </h4>", sep=""))
                }


})



histPValue <- reactive({
    rv$current.obj
    if (is.null(rv$current.obj)){ return()}
    
    if (is.null(rv$seuilPVal) ||
        is.null(rv$seuilLogFC) ||
        is.null(input$diffAnaMethod)
    ) {return()}
    
    t <- NULL
    # Si on a deja des pVal, alors, ne pas recalculer avec ComputeWithLimma
   # if (isContainedIn(c("logFC","P_Value"),names(Biobase::fData(rv$current.obj)) ) ){
  #      t <- Biobase::fData(rv$current.obj)[,"P_Value"]
  #  } else{
        data <- RunDiffAna()
        if (is.null(data)) {return ()}
        t <- data$P_Value
  #  }
    
    
    hist(sort(1-t), breaks=80, col="grey")
    
    
})

output$histPValue <- renderPlot({
    histPValue()
})



output$numericalValForCalibrationPlot <- renderUI({
    req(input$calibrationMethod)
    #if (is.null(input$calibrationMethod)) {return()}
    
    if (input$calibrationMethod == "numeric value"){
        numericInput( "numericValCalibration","Proportion of TRUE null hypohtesis", 
                      value = 0, min=0, max=1, step=0.05)
    }
})


output$calibrationResults <- renderUI({
    req(rv$calibrationRes)
    rv$seuilLogFC
    input$diffAnaMethod
    rv$current.obj
    
    
    txt <- paste("Non-DA protein proportion = ", 
                 round(100*rv$calibrationRes$pi0, digits = 2),"%<br>",
                 "DA protein concentration = ", 
                 round(100*rv$calibrationRes$h1.concentration, digits = 2),
                 "%<br>",
                 "Uniformity underestimation = ", 
                 rv$calibrationRes$unif.under,"<br><br><hr>", sep="")
    HTML(txt)
    
})




calibrationPlot <- reactive({
    rv$seuilPVal
    rv$seuilLogFC
    input$diffAnaMethod
    rv$resAnaDiff
    req(rv$current.obj)
    
    if (is.null(rv$seuilLogFC) || is.na(rv$seuilLogFC) ||
        (length(rv$resAnaDiff$logFC) == 0)) { return()}
    if (length(which(is.na(Biobase::exprs(rv$current.obj)))) > 0) {
        return()}
    cond <- c(rv$resAnaDiff$condition1, rv$resAnaDiff$condition2)
    # ________
    
    if (is.null(input$calibrationMethod)  ) {return()}
    
    t <- NULL
    method <- NULL
    t <- rv$resAnaDiff$P_Value
    t <- t[which(abs(rv$resAnaDiff$logFC) >= rv$seuilLogFC)]
    toDelete <- which(t==1)
    if (length(toDelete) > 0){
	t <- t[-toDelete]
     }
    
    
    
    l <- NULL
    ll <- NULL
    result = tryCatch(
        {
            
            if ((input$calibrationMethod == "numeric value") 
                && !is.null(input$numericValCalibration)) {
                
                ll <-catchToList(
                    wrapperCalibrationPlot(t, 
                                           as.numeric(input$numericValCalibration)))
                rv$errMsgCalibrationPlot <- ll$warnings[grep( "Warning:", ll$warnings)]
            }
            else if (input$calibrationMethod == "Benjamini-Hochberg") {
                
                ll <-catchToList(wrapperCalibrationPlot(t, 1))
                rv$errMsgCalibrationPlot <- ll$warnings[grep( "Warning:", ll$warnings)]
            }else { 
                ll <-catchToList(wrapperCalibrationPlot(t, input$calibrationMethod))
                rv$errMsgCalibrationPlot <- ll$warnings[grep( "Warning:", ll$warnings)]
            }
            
        }
        , warning = function(w) {
            shinyjs::info(paste("Calibration plot",":",
                                conditionMessage(w), sep=" "))
        }, error = function(e) {
            shinyjs::info(paste("Calibration plot",":",
                                conditionMessage(e), sep=" "))
        }, finally = {
            #cleanup-code 
        })
    
    
})

output$calibrationPlot <- renderPlot({
    calibrationPlot()
})



output$errMsgCalibrationPlot <- renderUI({
    req(rv$errMsgCalibrationPlot)
    rv$seuilLogFC
    req(rv$current.obj)
    
    txt <- NULL
    
    for (i in 1:length(rv$errMsgCalibrationPlot)) {
        txt <- paste(txt, "errMsgCalibrationPlot: ",rv$errMsgCalibrationPlot[i], "<br>", sep="")
    }
    
    div(HTML(txt), style="color:red")
    
})


output$errMsgCalibrationPlotAll <- renderUI({
    rv$errMsgCalibrationPlotAll
    rv$seuilLogFC
    rv$current.obj
    if (is.null(rv$current.obj) ) {return()}
    if (is.null(rv$errMsgCalibrationPlotAll) ) {return()}
    
    txt <- NULL
    for (i in 1:length(rv$errMsgCalibrationPlotAll)) {
        txt <- paste(txt, "errMsgCalibrationPlotAll:", rv$errMsgCalibrationPlotAll[i], "<br>", sep="")
    }
    
    div(HTML(txt), style="color:red")
})



calibrationPlotAll <- reactive({
    rv$seuilPVal
    rv$seuilLogFC
    input$diffAnaMethod
    rv$resAnaDiff
    rv$current.obj
    if (is.null(rv$current.obj) ) {return()}
    
    if ( is.null(rv$seuilLogFC) || is.na(rv$seuilLogFC) ||
        (length(rv$resAnaDiff$logFC) == 0)) { return()}
    if (length(which(is.na(Biobase::exprs(rv$current.obj)))) > 0) {
        return()}
    cond <- c(rv$resAnaDiff$condition1, rv$resAnaDiff$condition2)
    # ________
    
    if (is.null(input$calibrationMethod)  ) {return()}
    
    t <- NULL
    method <- NULL
    t <- rv$resAnaDiff$P_Value
    t <- t[which(abs(rv$resAnaDiff$logFC) >= rv$seuilLogFC)]
    toDelete <- which(t==1)
    if (length(toDelete) > 0){
        t <- t[-toDelete]
     }
    
    l <- NULL
    result = tryCatch(
        {
            l <-catchToList(wrapperCalibrationPlot(t, "ALL")  )
            rv$errMsgCalibrationPlotAll <- l$warnings[grep( "Warning:", 
                                                            l$warnings)]
        }
        , warning = function(w) {
            shinyjs::info(paste("Calibration Plot All methods",":",
                                conditionMessage(w), sep=" "))
        }, error = function(e) {
            shinyjs::info(paste("Calibration Plot All methods",":",
                                conditionMessage(e), sep=" "))
        }, finally = {
            #cleanup-code 
        })
    
})



#--------------------------------------------------
output$calibrationPlotAll <- renderPlot({
    calibrationPlotAll()
})


# 
# observe({
#   rv$res_AllPairwiseComparisons
#   rv$seuilPVal 
#   rv$seuilLogFC
#   input$selectComparison
#   input$anaDiff_Design
#   input$diffAnaMethod
#   input$ttest_options
#   
#   #shinyjs::disable("ValidDiffAna")
#   
#   shinyjs::enable("ValidDiffAna")
# })



#----------------------------------------------
observeEvent(input$ValidDiffAna,{ 
    req(rv$current.obj)
    rv$resAnaDiff
    req(rv$res_AllPairwiseComparisons)
    
    if ((input$ValidDiffAna == 0)) { return()}
    if (length(which(is.na(Biobase::exprs(rv$current.obj)))) > 0) { return()}

     
    ### Save one comparison if exists            
    # if (! (is.null(rv$resAnaDiff$logFC))  ){  
    #             m <- NULL
    #             if (input$calibrationMethod == "Benjamini-Hochberg") 
    #             { m <- 1}
    #             else if (input$calibrationMethod == "numeric value") 
    #             {m <- as.numeric(input$numericValCalibration)}
    #             else {m <- input$calibrationMethod }
    #             
    #             l.params <- NULL
    #             l.params[["comp"]] <- input$selectComparison
    #             l.params[["th_pval"]] <- rv$seuilPVal
    #             l.params[["calibMethod"]] <- input$calibrationMethod
    #             l.params[["fdr"]] <- diffAnaComputeFDR(rv$resAnaDiff[["logFC"]], 
    #                                                    rv$resAnaDiff[["P_Value"]],
    #                                                    rv$seuilPVal, 
    #                                                    rv$seuilLogFC,
    #                                                    m)
    #             l.params[["swapVolcano"]] <-  input$swapVolcano
    #             l.params[["filterType"]] <-  input$AnaDiff_ChooseFilters
    #             if( is.null(input$AnaDiff_seuilNA)) {
    #                 l.params[["filter_th_NA"]] <- NULL
    #                 } else {
    #                     l.params[["filter_th_NA"]] <-  input$AnaDiff_seuilNA
    #                 }
    #             l.params[["numValCalibMethod"]] <- input$numericValCalibration
    #             
    # }
                #temp <- DAPAR::diffAnaSave(temp,rv$resAnaDiff,l.params)
                
                
                #name <- paste("DiffAnalysis - ", rv$typeOfDataset, sep="")
                
               # rv$dataset[[name]] <- temp
               # rv$current.obj <- temp
               # UpdateLog("anaDiff", l.params)
                
                #updateSelectInput(session, "datasets", 
                #                  #paste("Dataset versions of",rv$current.obj.name, sep=" "),
                #                  choices = names(rv$dataset),
                #                  selected = name)

                
                updateSelectInput(session,"selectComparison", selected=input$selectComparison)
                updateCheckboxInput(session,"swapVolcano", value=input$swapVolcano )
                updateRadioButtons(session, "AnaDiff_ChooseFilters", selected=input$AnaDiff_ChooseFilters)
                updateSelectInput(session, "AnaDiff_seuilNA", selected=input$AnaDiff_seuilNA)
                
               # shinyjs::disable("ValidDiffAna")
                
                ####write command Log file
                #if (input$showCommandLog){
                # writeToCommandLogFile(paste("cond1 <- '", rv$resAnaDiff$condition1, "'", sep=""))
                # writeToCommandLogFile(paste("cond2 <- '", rv$resAnaDiff$condition2, "'", sep=""))
                # writeToCommandLogFile(paste("method <- '", input$diffAnaMethod, "'", sep=""))
                # 
                # switch(input$diffAnaMethod,
                #        Limma = writeToCommandLogFile("data <- wrapper.diffAnaLimma(current.obj, cond1, cond2)"),
                #        Welch =  writeToCommandLogFile( "data <- wrapper.diffAnaWelch(current.obj, cond1, cond2)")
                # )
                # 
                # 
                # writeToCommandLogFile(paste("threshold_pValue <- ", input$seuilPVal, sep=""))
                # writeToCommandLogFile(paste("threshold_logFC <- ", input$seuilLogFC,sep=""))
                # 
                # writeToCommandLogFile(paste("calibMethod <- \"", input$calibrationMethod, "\"", sep=""))
                # if (input$calibrationMethod == "Benjamini-Hochberg") { 
                #     writeToCommandLogFile("m <- 1") }
                # else if (input$calibrationMethod == "numeric value") 
                # { writeToCommandLogFile(paste(" m <- ",as.numeric(input$numericValCalibration), sep=""))}
                # else {writeToCommandLogFile("m <- calibMethod")}
                # 
                # writeToCommandLogFile("fdr <- diffAnaComputeFDR(data, threshold_pValue, threshold_logFC, m)")
                # 
                # 
                # writeToCommandLogFile(paste(" temp <- diffAnaSave(dataset[['",
                #                             input$datasets,"']],  data, method, cond1, cond2, threshold_pValue, threshold_logFC, fdr, calibMethod)", sep=""))
                # writeToCommandLogFile(paste(" name <- \"DiffAnalysis.", 
                #                             input$diffAnaMethod, " - ", rv$typeOfDataset,"\"", sep="" ))
                # writeToCommandLogFile("dataset[[name]] <- temp")
                # writeToCommandLogFile("current.obj <- temp")
                # # }
                # 
                # 
                # cMethod <- NULL
                # if (input$calibrationMethod == "numeric value"){
                #     cMethod <- paste("The proportion of true null
                #                      hypotheses was set to", 
                #                      input$numericValCalibration, sep= " ")}
                # else {cMethod <-input$calibrationMethod }
                
                
                
                #updateTabsetPanel(session, "abc", selected = "ValidateAndSaveAnaDiff")
                #shinyjs::disable("seuilLogFC")
                #shinyjs::disable("anaDiff_Design")
                #shinyjs::disable("diffAnaMethod")
                
                
                
                ## Add the necessary text to the Rmd file
                # txt2Rmd <- readLines("Rmd_sources/anaDiff_Rmd.Rmd")
                # filename <- paste(tempdir(), sessionID, 'report.Rmd',sep="/")
                # write(txt2Rmd, file = filename,append = TRUE, sep = "\n")
                #createPNG_DifferentialAnalysis()
  
            #}
})


output$DiffAnalysisSaved <- renderUI({
    #input$datasets
    #rv$current.obj
    if (is.null(input$datasets) || (length(grep("DiffAnalysis.",input$datasets)) !=1) ) {
        return()  }
    else if (grep("DiffAnalysis.",input$datasets) == 1 ) {
        h4("The differential analysis has been saved.")
    }
})






output$equivPVal <- renderText ({
    req(input$seuilPVal)
    input$diffAnaMethod
    req(rv$current.obj)
    input$selectComparison
    
    
    if (is.null(input$selectComparison) || (input$selectComparison=="None")){return()}
    if (is.null(input$diffAnaMethod) || (input$diffAnaMethod == G_noneStr))
    {return(NULL)}
     if (length(which(is.na(Biobase::exprs(rv$current.obj)))) > 0) {
        return()}
    
    HTML(paste("<h4>(p-value = ",
               signif(10^(- (input$seuilPVal)), digits=3), ") </h4>", sep=""))
})


output$equivLog10 <- renderText ({
    req(input$test.threshold)
    req(rv$current.obj)
    req(input$diffAnaMethod)
    if (length(which(is.na(Biobase::exprs(rv$current.obj)))) > 0) {
        return()}
    
    HTML(paste("<h4>-log10 (p-value) = ",
               signif(- log10(input$test.threshold/100), digits=1),
               "</h4>", sep=""))
})


##update diffAna Panel
# observeEvent(rv$current.obj,{
#     
#     if (length(which(is.na(Biobase::exprs(rv$current.obj)))) > 0) {
#         return()}
#     
#     if ("P_Value"  %in% names(Biobase::fData(rv$current.obj))){
#         
#         updateSelectInput(session,"diffAnaMethod",
#                           selected =  rv$current.obj@experimentData@other$method)
#         
#         updateNumericInput(session,
#                            "seuilPVal",
#                            min = 0,
#                            max = max(-log10(Biobase::fData(rv$current.obj)$P_Value)),
#                            value = rv$current.obj@experimentData@other$threshold_p_value, 
#                            step=0.1)
#         
#         updateNumericInput(session,
#                            "seuilLogFC", 
#                            min = 0, 
#                            max = max(abs(Biobase::fData(rv$current.obj)$logFC)), 
#                            value = rv$current.obj@experimentData@other$threshold_logFC, 
#                            step=0.1)
#     }
#     
# })

observeEvent(input$seuilPVal,{
       rv$seuilPVal <- as.numeric(input$seuilPVal)
})


########################################################
output$showSelectedItems <- DT::renderDataTable({
    req(rv$current.obj)
    req(input$diffAnaMethod)
    req(input$seuilLogFC)
    req(input$seuilPVal)
    req(input$selectComparison)
    req(input$showpvalTable)
    input$tooltipInfo
    
    if ((input$selectComparison == "None") || (input$diffAnaMethod == "None")) 
    {return()}

    if (length(which(is.na(Biobase::exprs(rv$current.obj)))) > 0) {return()}

            t <- NULL
            # Si on a deja des pVal, alors, ne pas recalculer avec ComputeWithLimma
            # if (isContainedIn(c("logFC","P_Value"),names(Biobase::fData(rv$current.obj)) ) ){
            #     selectedItems <- (which(Biobase::fData(rv$current.obj)$Significant == TRUE)) 
            #     t <- data.frame(id = rownames(Biobase::exprs(rv$current.obj))[selectedItems],
            #                     round(Biobase::fData(rv$current.obj)[selectedItems,
            #                                                    c("logFC", "P_Value", "Significant")], digits=input$settings_nDigits))
            # } else{
                data <- rv$resAnaDiff
                upItems1 <- which(-log10(data$P_Value) >= rv$seuilPVal)
                upItems2 <- which(abs(data$logFC) >= rv$seuilLogFC)
                selectedItems <- intersect(upItems1, upItems2)
                
                 t <- data.frame(id = rownames(Biobase::exprs(rv$current.obj))[selectedItems],
                                logFC = round(data$logFC[selectedItems], digits=input$settings_nDigits),
                                P_Value = round(data$P_Value[selectedItems], digits=input$settings_nDigits))
                 t <- cbind(t, Biobase::fData(rv$current.obj)[selectedItems,input$tooltipInfo])
            #}
            
            DT::datatable(t,
            extensions = c('Scroller','Buttons'),
            rownames=FALSE,
            options = list(
                initComplete = initComplete(),
                deferRender = TRUE,
                bLengthChange = FALSE,
                scroolX = 300,
                scrollY = 300,
                scroller = TRUE,
                dom = 'Bfrtip',
                buttons = c('copy','excel', 'pdf')
            )
            )

})




isContainedIn <- function(strA, strB){
    return (all(strA %in% strB))
}
