ui.modules_pancan_cor_o2o = function(id) {
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
					mol_origin_UI(ns("mol_origin2cor"), database = "toil"),

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
					filter_samples_UI(ns("filter_samples2cor"), database = "toil"),
					br(),
					verbatimTextOutput(ns("filter_phe_id_info")),
					br(),

					h4(strong("S1.4 Upload metadata"),"[opt]") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Upload metadata", 
					                   content = "custom_metadata"),
					shinyFeedback::useShinyFeedback(),
					custom_meta_UI(ns("custom_meta2cor")),
					br(),

					h4(strong("S1.5 Add signature"),"[opt]") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Add signature", 
					                   content = "add_signature"),
					add_signature_UI(ns("add_signature2cor"), database = "toil"),
					br(),

				)
			),
			# 下载X/Y轴数据
			column(
				4,
				wellPanel(
					style = "height:1100px",
					h2("S2: Get data", align = "center"),
					# X
					h4(strong("S2.1 Get data for X-axis")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Get one data", 
					                   content = "get_one_data"), 
					download_feat_UI(ns("download_x_axis"), 
						button_name="Query", database = "toil"),
		            # br(),
		            # Y
		            h4(strong("S2.2 Get data for Y-axis")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Get one data", 
					                   content = "get_one_data"),  
					download_feat_UI(ns("download_y_axis"), 
						button_name="Query", database = "toil")
				)
			),
			# 分析/绘图/下载
			column(
				5,
				wellPanel(
					h2("S3: Analyze & Visualize", align = "center") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Analyze & Visualize", 
					                   content = "analyze_cor_1"),  
					style = "height:1100px",
					h4(strong("S3.1 Set analysis parameters")), 
					selectInput(ns("cor_method"), "Correlation method:",choices = c("Spearman", "Pearson"),selected="Spearman"),
					h4(strong("S3.2 Set visualization parameters")), 
					fluidRow(
						column(3, colourpicker::colourInput(inputId = ns("line_color"), "Line color:", "#0000FF")),
						column(3, colourpicker::colourInput(inputId = ns("x_hist_color"), "Hist color(x):", "#009E73")),
						column(3, colourpicker::colourInput(inputId = ns("y_hist_color"), "Hist color(y):", "#D55E00"))
					),
					dropMenu(
						actionBttn(ns("more_visu"), label = "Other options", style = "bordered",color = "success",icon = icon("bars")),
						div(h3("1. Select ggplot theme:"),style="width:400px;"),
						fluidRow(
							column(6,
								selectInput(inputId = ns("theme"), label = NULL, 
											choices = names(themes_list), selected = "ggstatplot")
							)
						),
						div(h3("2. Adjust points:"),style="width:400px;"),
						fluidRow(
							column(4, numericInput(inputId = ns("point_size"), label = "Point size:", value = 3, step = 0.5)),
							column(3, numericInput(inputId = ns("point_alpha"), label = "Point alpha:", value = 0.4, step = 0.1, min = 0, max = 1))
						),
						div(h3("3. Adjust text size:"),style="width:400px;"),
						fluidRow(
							column(4, numericInput(inputId = ns("axis_size"), label = "Text size:", value = 18, step = 0.5)),
							column(4, numericInput(inputId = ns("title_size"), label = "Title size:", value = 20, step = 0.5))
						),				
						div(h3("4. Adjust lab and title name:"),style="width:400px;"),
						fluidRow(
							column(4, textInput(inputId = ns("x_name"), label = "X-axis name:")),
							column(4, textInput(inputId = ns("y_name"), label = "Y-axis name:")),
							column(4, textInput(inputId = ns("title_name"), label = "Title name:"))
						),	
						div(h3("5. Display the histogram or not:"),style="width:400px;"),
						fluidRow(
							column(6, radioButtons(inputId = ns("side_hist"), label = NULL, 
								choices = c("NO", "YES"), selected="YES",inline = TRUE)),
						),	
						div(h5("Note: You can download the raw data and plot in local R environment for more detailed adjustment.")),
					),
					br(),
					shinyWidgets::actionBttn(
						ns("step3_plot_sct"), "Run",
				        style = "gradient",
				        icon = icon("chart-line"),
				        color = "primary",
				        block = TRUE,
				        size = "sm"
					),
					br(),
					fluidRow(
						column(10, offset = 1,
							   plotOutput({ns("cor_plot_sct")}, height = "480px") 
						)
					),
					br(),
					h4(strong("S3.3 Download results")), 
					download_res_UI(ns("download_res2cor"))
				)
			)
		)
	)
}


server.modules_pancan_cor_o2o = function(input, output, session) {
	ns <- session$ns

	# 记录选择癌症
	cancer_choose <- reactiveValues(name = "ACC", phe_primary="",
		filter_phe_id=query_tcga_group(database = "toil",cancer = "BRCA", return_all = T))
	observe({
		cancer_choose$name = input$choose_cancer
		cancer_choose$phe_primary <- query_tcga_group(database = "toil",cancer = cancer_choose$name, return_all = T)
	})

	# 自定义上传metadata数据
	custom_meta = callModule(custom_meta_Server, "custom_meta2cor", database = "toil")
	# # signature
	sig_dat = callModule(add_signature_Server, "add_signature2cor", database = "toil")
	# sig_dat = reactive({NULL})
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
	opt_pancan = callModule(mol_origin_Server, "mol_origin2cor", database = "toil")

	## 过滤样本
	# exact filter module
	filter_phe_id = callModule(filter_samples_Server, "filter_samples2cor",
					   database = "toil",
					   cancers=reactive(cancer_choose$name),
					   custom_metadata=reactive(custom_meta_sig()),
					   opt_pancan = reactive(opt_pancan()))

	# filter_phe_id = reactive({NULL})
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


	## x-axis panel
	x_axis_data = callModule(download_feat_Server, "download_x_axis", 
							 database = "toil",
							 samples=reactive(cancer_choose$filter_phe_id),
							 custom_metadata=reactive(custom_meta_sig()),
						     opt_pancan = reactive(opt_pancan()),
						     check_numeric=TRUE
							 )

	## y-axis panel
	y_axis_data = callModule(download_feat_Server, "download_y_axis", 
							 database = "toil",
							 samples=reactive(cancer_choose$filter_phe_id),
							 custom_metadata=reactive(custom_meta_sig()),
						     opt_pancan = reactive(opt_pancan()),
						     check_numeric=TRUE
							 )

	# 合并分析
	# scatterplot逻辑：先绘图，再提取相关性结果
	merge_data_sct = eventReactive(input$step3_plot_sct, {
		x_axis_data = x_axis_data()
		colnames(x_axis_data)[c(1:3,5)] = paste0("x_",colnames(x_axis_data)[c(1:3,5)])
		y_axis_data = y_axis_data()
		colnames(y_axis_data)[c(1:3,5)] = paste0("y_",colnames(y_axis_data)[c(1:3,5)])

		data = dplyr::inner_join(x_axis_data, y_axis_data) %>%
			dplyr::select(cancer, Sample, everything())
		data
	})

	observe({
		updateTextInput(session, "x_name", value = unique(x_axis_data()$id))
		updateTextInput(session, "y_name", value = unique(y_axis_data()$id))
		updateTextInput(session, "title_name", value = cancer_choose$name)
	})

	cor_plot_sct = eventReactive(input$step3_plot_sct, {
		shiny::validate(
			need(try(nrow(merge_data_sct())>0), 
				"Please inspect whether to get valid data in Step2."),
			need(try(nrow(merge_data_sct())>2), 
				"Please adjust to ensure that enough samples (n≥3) are included for analysis.")
		)
		p = plot_cor_o2o(
			data = merge_data_sct(), cor_method = input$cor_method,
			xlab = input$x_name, ylab = input$y_name, title = input$title_name, 
			point.args = list(size = input$point_size, alpha = input$point_alpha),
			smooth.line.args = list(color = input$line_color,linewidth = 1.5,method = "lm",formula = y ~ x),
			xsidehistogram.args = list(fill = input$x_hist_color, color = "black", na.rm = TRUE),
			ysidehistogram.args = list(fill = input$y_hist_color, color = "black", na.rm = TRUE),
			axis_size = input$axis_size, title_size = input$title_size, side_hist = input$side_hist,
			custom_theme = themes_list[[input$theme]]
		)
		return(p)
	})
	output$cor_plot_sct = renderPlot({cor_plot_sct()})

	# Download results
	observeEvent(input$step3_plot_sct,{
		res1 = cor_plot_sct()
		res2 = merge_data_sct()
		p_cor = extract_stats(cor_plot_sct())$subtitle_data
		p_cor = p_cor[-which(colnames(p_cor)=="expression")]
		p_cor$parameter1 = unique(merge_data_sct()$x_axis)
		p_cor$parameter2 = unique(merge_data_sct()$y_axis)
		p_cor = p_cor %>% dplyr::mutate(cancer = cancer_choose$name, .before=1)
		res3 = p_cor

		callModule(download_res_Server, "download_res2cor", res1, res2, res3)
	})
}