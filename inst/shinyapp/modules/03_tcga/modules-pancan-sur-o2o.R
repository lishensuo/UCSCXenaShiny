ui.modules_pancan_sur_o2o = function(id) {
	ns = NS(id)
	fluidPage(
		fluidRow(
			# 初始设置
			column(
				3,
				wellPanel(
					style = "height:1100px",
					h2("S1: Preset", align = "center"),
					h4(strong("S1.1 Modify datasets"),"[opt]") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Modify datasets", 
					                   content = "data_origin"),
					mol_origin_UI(ns("mol_origin2sur"), database = "toil"),

					h4(strong("S1.2 Choose cancer")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Cancer types", 
					                   content = "tcga_types"),
					pickerInput(
						ns("choose_cancer"), NULL,
						choices = sort(tcga_names)),
				    br(),

					h4(strong("S1.3 Filter samples"),"[opt]") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Filter samples", 
					                   content = "choose_samples"),
					h5("Quick filter:"),
					pickerInput(
						ns("filter_by_code"), NULL,
						choices = NULL, selected =  NULL,
						multiple = TRUE, options = list(`actions-box` = TRUE)
					),
					h5("Exact filter:"),
					filter_samples_UI(ns("filter_samples2sur"), database = "toil"),
					br(),
					verbatimTextOutput(ns("filter_phe_id_info")),
					br(),

					h4(strong("S1.4 Upload metadata"),"[opt]") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Upload metadata", 
					                   content = "custom_metadata"),
					shinyFeedback::useShinyFeedback(),
					custom_meta_UI(ns("custom_meta2sur")),
					br(),

					h4(strong("S1.5 Add signature"),"[opt]") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Add signature", 
					                   content = "add_signature"),
					add_signature_UI(ns("add_signature2sur"), database = "toil"),

				)
			),
			# 选择生存资料并设置分组
			column(
				4,
				wellPanel(
					style = "height:1100px",
					h2("S2: Get data", align = "center"),
					h4(strong("S2.1 Select survival endpoint")), 

				    shinyWidgets::prettyRadioButtons(
				        inputId = ns("endpoint_type"), label = NULL,
				        choiceValues = c("OS", "DSS", "DFI", "PFI"),
				        choiceNames = c("OS (Overall Survial)", "DSS (Disease-Specific Survival)", 
				        				"DFI (Disease-Free Interval)", "PFI (Progression-Free Interval)"),
				        selected = "OS"
				    ),
				    br(),br(),
					h4(strong("S2.2 Divide 2 groups by one condition")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Divide 2 groups", 
					                   content = "set_groups"),
				    group_samples_UI(ns("group_samples2sur"), database = "toil")  
				)
			),
			# 分析/可视化/下载
			column(
				5,
				wellPanel(
					style = "height:1100px",
					h2("S3: Analyze & Visualize", align = "center") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Analyze & Visualize", 
					                   content = "analyze_sur_1"),  
					h4(strong("S3.1 Set analysis parameters")), 
					selectInput(ns("sur_method"), "Survival method:",
						choices = c("Log-rank test", "Univariate Cox regression")),

				    materialSwitch(ns("use_origin"), 
				    	"Whether use initial data before grouping?"),
					h4(strong("S3.2 Set visualization parameters")), 
			      	uiOutput(ns("one_params.ui")),
					dropMenu(
						actionBttn(ns("more_visu"), label = "Other options", style = "bordered",color = "success",icon = icon("bars")),
						div(h3(strong("Params for Log-rank test")),style="width:500px;"),
						div(h4("1. Wheather to dislpay risk.table:"),style="width:500px;"),
						fluidRow(
							column(6, radioButtons(inputId = ns("plot_table"), label = NULL, 
								choices = c("NO", "YES"), selected="NO",inline = TRUE)),
						),
						div(h4("2. Wheather to dislpay ncensor.plot:"),style="width:500px;"),
						fluidRow(
							column(6, radioButtons(inputId = ns("plot_ncensor"), label = NULL, 
								choices = c("NO", "YES"), selected="NO",inline = TRUE)),
						),
						div(h4("3. Wheather to dislpay confidence interval:"),style="width:500px;"),
						fluidRow(
							column(12, radioButtons(inputId = ns("plot_CI"), label = NULL, 
								choices = c("NO", "YES(ribbon)", "YES(step)"), selected="NO",inline = TRUE)),
						),	
						div(h4("2. Adjust text size:"),style="width:400px;"),
						fluidRow(
							column(4, numericInput(inputId = ns("axis_size"), label = "Text size:", value = 14, step = 0.5)),
							column(4, numericInput(inputId = ns("title_size"), label = "Title size:", value = 18, step = 0.5))
						),	
						div(h4("4. Adjust lab and title name:"),style="width:500px;"),
						fluidRow(
							column(4, textInput(inputId = ns("x_name"), label = "X-axis name:")),
							column(4, textInput(inputId = ns("title_name"), label = "Title name:"))
						),	
						div(h3(strong("Params for Cox regression")),style="width:500px;"),
						div(h4("1. Adjust text size:"),style="width:400px;"),
						fluidRow(
							column(4, numericInput(inputId = ns("axis_size_2"), label = "Font size:", value = 0.7, step = 0.1)),
						),	
						div(h4("2. Adjust lab and title name:"),style="width:500px;"),
						fluidRow(
							column(4, textInput(inputId = ns("title_name_2"), label = "Title name:", value = "Hazard ratio"))
						),	
						div(h5("Note: You can download the raw data and plot in local R environment for more detailed adjustment.")),
					),
					br(),
					shinyWidgets::actionBttn(
						ns("sur_analysis_bt_single"), "Run",
				        style = "gradient",
				        icon = icon("chart-line"),
				        color = "primary",
				        block = TRUE,
				        size = "sm"
					),
					br(),
					fluidRow(
						column(10, offset = 1,
							   plotOutput({ns("sur_plot_one")}, height = "500px") 
						)
					),
					br(),
					h4(strong("S3.3 Download results")), 
					download_res_UI(ns("download_res2sur"))
				)
			)
		)
	)
}

server.modules_pancan_sur_o2o = function(input, output, session) {
	ns <- session$ns

	# 记录选择癌症
	cancer_choose <- reactiveValues(name = "BRCA", filter_phe_id=NULL,
		phe_primary=query_tcga_group(database = "toil",cancer = "BRCA", return_all = T))
	observe({
		cancer_choose$name = input$choose_cancer
		cancer_choose$phe_primary <- query_tcga_group(database = "toil",cancer = cancer_choose$name, return_all = T)
	})

	# 自定义上传metadata数据
	custom_meta = callModule(custom_meta_Server, "custom_meta2sur",database = "toil")
	# signature
	sig_dat = callModule(add_signature_Server, "add_signature2sur",database = "toil")

	custom_meta_sig = reactive({
		if(is.null(custom_meta())){
			return(sig_dat())
		} else {
			if(is.null(sig_dat())){
				return(custom_meta())
			} else {
				custom_meta_sig = dplyr::inner_join(custom_meta(),sig_dat())
				return(custom_meta_sig)
			}
		}
	})

	# 数据源设置
	opt_pancan = callModule(mol_origin_Server, "mol_origin2sur", database = "toil")


	## 过滤样本
	# exact filter module
	filter_phe_id = callModule(filter_samples_Server, "filter_samples2sur",
					   database = "toil",
					   cancers=reactive(cancer_choose$name),
					   custom_metadata=reactive(custom_meta_sig()),
					   opt_pancan = reactive(opt_pancan()))
	# quick filter widget
	observe({
		code_types_valid = code_types[names(code_types) %in% 
							unique(cancer_choose$phe_primary$Code)]
		updatePickerInput(
			session,
			"filter_by_code",
			choices = unlist(code_types_valid,use.names = F),
			selected =  unlist(code_types_valid,use.names = F)
		)
	})
	# 综合上述二者
	observe({
		# quick filter
		choose_codes = names(code_types)[unlist(code_types) %in% input$filter_by_code]
		filter_phe_id2 = cancer_choose$phe_primary %>%
			dplyr::filter(Code %in% choose_codes) %>%
			dplyr::pull("Sample")

		# exact filter
		if(is.null(filter_phe_id())){
			cancer_choose$filter_phe_id = filter_phe_id2
		} else {
			cancer_choose$filter_phe_id = intersect(filter_phe_id2,filter_phe_id())
		}

		output$filter_phe_id_info = renderPrint({
			cat(paste0("Tip: ", length(cancer_choose$filter_phe_id), " samples are retained"))
		})
	})


	# 生存资料
	sur_dat_v1 = reactive({
		sur_dat_raw = load_data("tcga_surv") %>% dplyr::rename("Sample"="sample")
		cli_dat_raw = load_data("tcga_clinical") %>% dplyr::rename("Sample"="sample")
		sur_dat_sub = sur_dat_raw %>%
			dplyr::filter(Sample %in% cancer_choose$filter_phe_id) %>%
			dplyr::select("Sample",contains(input$endpoint_type)) %>%
			dplyr::mutate(cancer = cli_dat_raw$type[match(Sample,cli_dat_raw$Sample)],.before = 1) %>%
			na.omit()
		colnames(sur_dat_sub)[3:4] = c("status","time")
		sur_dat_sub
	})

	# 设置分组
	group_final = callModule(group_samples_Server, "group_samples2sur",
					   	   database = "toil",
						   cancers=reactive(cancer_choose$name),
						   samples=reactive(sur_dat_v1()$Sample),
						   custom_metadata=reactive(custom_meta_sig()),
						   opt_pancan = reactive(opt_pancan())
						   )

	# 合并分组与生存
	sur_res_one = reactiveValues(sur_dat = NULL, cutoff=NULL, sur_res = NULL)

	group_sur_final = reactive({
		dat = dplyr::inner_join(group_final(),sur_dat_v1()[,-1],by=c("Sample"="Sample"))
		## 验证是否只有一组分组的癌症
		dat = dat %>%
			dplyr::filter(Cancer %in% sort(unique(dat$Cancer))[
				apply(table(dat$Cancer,dat$group),1,function(x) {min(x)>=1})])
		dat
	})

	output$one_params.ui = renderUI(
		if(input$sur_method=="Log-rank test"){
		  	fluidRow(
		  		column(4,colourpicker::colourInput(ns("one_log_color1"), "Color (Group 1):", "#E7B800")),
		  		column(4,colourpicker::colourInput(ns("one_log_color2"), "Color (Group 2):", "#2E9FDF")),
		  	)
		} else if(input$sur_method=="Univariate Cox regression") {
			fluidRow(
				column(4,numericInput(ns("text_c1"), "Position of text col-1", 0.02, step = 0.01)),
				column(4,numericInput(ns("text_c2"), "text col-2", 0.22, step = 0.01)),
				column(4,numericInput(ns("text_c3"), "text col-3", 0.4, step = 0.01))
			)
		}
	)

	# 生存分析的输入（供绘图）与输出结果（供下载）
	observeEvent(input$sur_analysis_bt_single, {
		sur_res_one$sur_dat = group_sur_final()

		if(input$sur_method=="Log-rank test"){
			if(!input$use_origin){ #是否使用分组前的原始值
				sur_res_one$sur_dat$Group = sur_res_one$sur_dat$group
			} else {
				if(class(group_sur_final()$origin) != "character"){ #若原始值为数值型，则寻找最佳阈值
					res.cut <- surv_cutpoint(sur_res_one$sur_dat, time = "time", event = "status", variables = "origin")
					groups_1_2 = sur_res_one$sur_dat %>% 
						  dplyr::group_by(group) %>% 
						  dplyr::summarise(mean = mean(origin)) %>% 
						  dplyr::arrange(mean) %>% 
						  dplyr::pull(group) %>% as.character()
					sur_res_one$sur_dat$Group = ifelse(surv_categorize(res.cut)$origin=="low", groups_1_2[1], groups_1_2[2])
					sur_res_one$sur_dat$Group = factor(sur_res_one$sur_dat$Group, levels=groups_1_2)
				} else {
					sur_res_one$sur_dat$Group = sur_res_one$sur_dat$group # 若不是，则仍使用提供的分组结果
				}
			}
			# print(head(sur_res_one$sur_dat))
			surv_diff <- survdiff(Surv(time, status) ~ Group, data = sur_res_one$sur_dat)
			pval = 1 - pchisq(surv_diff$chisq, length(surv_diff$n) - 1)
			sur_res_one$sur_res = summary(survfit(Surv(time, status) ~ Group, data = sur_res_one$sur_dat))$table %>% 
				    as.data.frame() %>% tibble::rownames_to_column("Group") %>% 
				    dplyr::mutate(Cancer = cancer_choose$name, .before = 1) %>% 
				    dplyr::mutate(p.value = pval)

		} else if (input$sur_method=="Univariate Cox regression"){
			if(!input$use_origin){
				sur_res_one$sur_dat$Group = sur_res_one$sur_dat$group
			} else {
				if(class(group_sur_final()$origin) != "character"){
					sur_res_one$sur_dat$Group = sur_res_one$sur_dat$origin
				} else {
					sur_res_one$sur_dat$Group = sur_res_one$sur_dat$group
				}
			}
			fit <- coxph(Surv(time, status) ~ Group, data = sur_res_one$sur_dat)
			# sur_res_one$pval = summary(fit)$coefficients[1,5]
			sur_res_one$sur_res = summary(fit)$coefficients %>% as.data.frame()
		}
	})


 	observe({
		updateTextInput(session, "x_name", value = paste(input$endpoint_type, "(days)"))
		updateTextInput(session, "title_name", value = NULL)
 	})


	sur_plot_one = eventReactive(input$sur_analysis_bt_single,{
		shiny::validate(
			need(try(nrow(sur_res_one$sur_dat)>0), 
				"Please inspect whether to set valid groups in S3 step."),
		)
		p = plot_sur_o20(
			sur_res_one$sur_dat, plot_CI=input$plot_CI, plot_table=input$plot_table, 
			plot_ncensor=input$plot_ncensor, sur_method=input$sur_method,
        	one_log_color1=input$one_log_color1, one_log_color2=input$one_log_color2, 
			axis_size=input$axis_size, x_name=input$x_name, 
			title_name=input$title_name, title_size=input$title_size,
        	text_c1=input$text_c1, text_c2=input$text_c2, text_c3=input$text_c3,
			axis_size_2=input$axis_size_2, title_name_2=input$title_name_2)
		p
	})

	output$sur_plot_one = renderPlot({sur_plot_one()})

	# Download results
	observeEvent(input$sur_analysis_bt_single,{
		res1 = sur_plot_one()
		res2 = sur_res_one$sur_dat
		res3 = sur_res_one$sur_res
		callModule(download_res_Server, "download_res2sur", res1, res2, res3)
	})
}