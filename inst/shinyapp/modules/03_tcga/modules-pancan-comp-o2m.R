ui.modules_pancan_comp_o2m = function(id) {
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
					mol_origin_UI(ns("mol_origin2comp"), database = "toil"),

					h4(strong("S1.2 Choose cancers")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Cancer types", 
					                   content = "tcga_types"),
					pickerInput(
						ns("choose_cancers"), NULL,
						choices = sort(tcga_names),
						multiple = TRUE,
						selected = sort(tcga_names),
						options = list(`actions-box` = TRUE)
					),
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
					filter_samples_UI(ns("filter_samples2comp"), database = "toil"),
					br(),
					verbatimTextOutput(ns("filter_phe_id_info")),
					br(),

					h4(strong("S1.4 Upload metadata"),"[opt]") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Upload metadata", 
					                   content = "custom_metadata"),
					shinyFeedback::useShinyFeedback(),
					custom_meta_UI(ns("custom_meta2comp")),
					br(),

					h4(strong("S1.5 Add signature"),"[opt]") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Add signature", 
					                   content = "add_signature"),
					add_signature_UI(ns("add_signature2comp"), database = "toil")

				)
			),
			# 分组设置
			column(
				4,
				wellPanel(
					style = "height:1100px",
					h2("S2: Get data", align = "center"),
					h4(strong("S2.1 Divide 2 groups by one condition")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Divide 2 groups", 
					                   content = "set_groups"),
					# 调用分组模块UI
					group_samples_UI(ns("group_samples2comp"), database = "toil"),  
					h4(strong("S2.2 Get data for comparison")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Get one data", 
					                   content = "get_one_data"), 
					# 下载待比较数据
					download_feat_UI(ns("download_y_axis"), button_name="Query", database = "toil")

				)
			),
			# 分析/绘图/下载
			column(
				5,
				wellPanel(
					h2("S3: Analyze & Visualize", align = "center") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Analyze & Visualize", 
					                   content = "analyze_comp_2"),  
					style = "height:1100px",

					h4(strong("S3.1 Set analysis parameters")),
					selectInput(ns("comp_method"), "Comparison method:",choices = c("wilcoxon","t-test"),selected="wilcoxon"),
					shinyWidgets::actionBttn(
						ns("step3_plot_line_1"), "Run (Calculate)",
				        style = "gradient",
				        icon = icon("chart-line"),
				        color = "primary",
				        block = TRUE,
				        size = "sm"
					),
					verbatimTextOutput(ns("message1")),
					h4(strong("S3.2 Set visualization parameters")), 
					fluidRow(
						column(3, colourpicker::colourInput(inputId = ns("group_1_color_2"), "Color (Group 1):", "#E69F00")),
						column(3, colourpicker::colourInput(inputId = ns("group_2_color_2"), "Color (Group 2):", "#56B4E9")),
					),
					dropMenu(
						actionBttn(ns("more_visu"), label = "Other options", style = "bordered",color = "success",icon = icon("bars")),
						div(h3("1. Select ggplot theme:"),style="width:400px;"),
						fluidRow(
							column(6,
								selectInput(inputId = ns("theme"), label = NULL, 
											choices = names(themes_list), selected = "Minimal")
							)
						),
						div(h3("2. Significance display:"),style="width:400px;"),
						fluidRow(
							column(6, radioButtons(inputId = ns("significance"), label = "Significance:", 
								choices = c("Value", "Symbol"), selected="Symbol",inline = TRUE)),
						),
						div(h3("3. Adjust text size:"),style="width:400px;"),
						fluidRow(
							column(4, numericInput(inputId = ns("axis_size"), label = "Text size:", value = 18, step = 0.5)),
							column(4, numericInput(inputId = ns("title_size"), label = "Title size:", value = 20, step = 0.5)),
							column(4, numericInput(inputId = ns("label_size"), label = "Label size:", value = 5, step = 0.5)),
						),				
						div(h3("4. Adjust lab and title name:"),style="width:400px;"),
						fluidRow(
							column(4, textInput(inputId = ns("x_name"), label = "X-axis name:")),
							column(4, textInput(inputId = ns("title_name"), label = "Title name:",
								value = NULL))
						),	
						div(h5("Note: You can download the raw data and plot in local R environment for more detailed adjustment.")),
					),
					br(),
					shinyWidgets::actionBttn(
						ns("step3_plot_line_2"), "Run (Visualize)",
				        style = "gradient",
				        icon = icon("chart-line"),
				        color = "primary",
				        block = TRUE,
				        size = "sm"
					),
					br(),
					fluidRow(
						column(10, offset = 1,
							   plotOutput({ns("comp_plot_line")}, height = "480px") 
						)
					),

					h4(strong("S3.3 Download results")), 
				    download_res_UI(ns("download_res2comp"))
				)
			)
		)
	)
}


server.modules_pancan_comp_o2m = function(input, output, session) {
	ns <- session$ns

	# 记录选择癌症
	cancer_choose <- reactiveValues(name = "BRCA", 
		phe_primary=query_tcga_group(database = "toil",cancer = "BRCA", return_all = T),
		filter_phe_id=NULL, single_cancer_ok = TRUE)
	observe({
		cancer_choose$name = input$choose_cancers
		cancer_choose$phe_primary <- query_tcga_group(database = "toil",cancer = cancer_choose$name, return_all = T)
	})

	# 自定义上传metadata数据
	custom_meta = callModule(custom_meta_Server, "custom_meta2comp", database = "toil")

	# signature
	sig_dat = callModule(add_signature_Server, "add_signature2comp", database = "toil")
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
	opt_pancan = callModule(mol_origin_Server, "mol_origin2comp", database = "toil")

	## 过滤样本
	# exact filter module
	filter_phe_id = callModule(filter_samples_Server, "filter_samples2comp",
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


	# 设置分组
	group_final = callModule(group_samples_Server, "group_samples2comp",
					   	   database = "toil",
						   cancers=reactive(cancer_choose$name),
						   samples=reactive(cancer_choose$filter_phe_id),
						   custom_metadata=reactive(custom_meta_sig()),
						   opt_pancan = reactive(opt_pancan())
						   )


	# 下载待比较数据
	y_axis_data = callModule(download_feat_Server, "download_y_axis", 
							 database = "toil",
							 samples=reactive(cancer_choose$filter_phe_id),
							 custom_metadata=reactive(custom_meta_sig()),
						     opt_pancan = reactive(opt_pancan()),
						     check_numeric=TRUE,
						     table.ui = FALSE
							 )

	# barplot逻辑：先批量计算相关性，再绘图
	merge_data_line = eventReactive(input$step3_plot_line_1, {
		group_data = group_final()[,c(1,3,4)]
		colnames(group_data) = c("Sample","group","phenotype")
		y_axis_data = y_axis_data()
		data = dplyr::inner_join(y_axis_data, group_data) %>%
			dplyr::select(cancer, Sample, value, group, everything())
		data
	})
	# 仍需要检查数据，因为即使二分组本身成立，但可能样本缺失variable数据导致仍然只有一个分组
	observe({
		cancer_choose$multi_cancer_ok = 
		    merge_data_line() %>%
		      dplyr::group_by(cancer, group) %>%
		      dplyr::summarise(n1=n()) %>%
		      dplyr::filter(n1>=3) %>% # 每小组的样本数大于等于3
		      dplyr::distinct(cancer, group) %>%
		      dplyr::count(cancer,name = "n2") %>%
		      dplyr::filter(n2==2) %>% dplyr::pull("cancer") # 每个肿瘤有两组
	})


	comp_data_line = eventReactive(input$step3_plot_line_1, {
		merge_data_line = merge_data_line()
		shinyjs::disable("step3_plot_line_1")
		comp_method = switch(isolate(input$comp_method),
			`t-test` = "parametric", wilcoxon = "nonparametric")
		valid_cancer_choose = sort(cancer_choose$multi_cancer_ok)

		withProgress(message = "Please wait for a while.",{
			stat_comp = lapply(seq(valid_cancer_choose), function(i){
			tcga_type = valid_cancer_choose[i]
			p = ggbetweenstats(
				subset(merge_data_line, cancer==tcga_type),
				x = "group",
				y = "value",
				type = comp_method)
			incProgress(1 / length(valid_cancer_choose), detail = paste0("(Finished ",i,"/",length(valid_cancer_choose),")"))
			return(extract_stats(p)$subtitle_data)
			}) %>% do.call(rbind, .) %>% 
			dplyr::select(!expression) %>% 
			dplyr::mutate(cancer = valid_cancer_choose, .before=1) %>% 
			dplyr::arrange(desc(cancer)) %>%
			dplyr::mutate(cancer = factor(cancer, levels = unique(cancer)))
			stat_comp
		})
		shinyjs::enable("step3_plot_line_1")
		stat_comp
	})
	output$message1 = renderPrint({
		req(comp_data_line())
		shiny::validate(
			need(try(nrow(comp_data_line())>0), 
				"Please inspect whether to download valid data in S2 step."),
		)
		cat(paste("The calculation has been successfully completed! (",format(Sys.time(), "%H:%M:%S"),")"))
	})

	observe({
		updateTextInput(session, "x_name", value = unique(y_axis_data()$id))
		# updateTextInput(session, "y_name", value = unique(y_axis_data()$id))
		updateTextInput(session, "title_name", value = "")
	})

	comp_plot_line = eventReactive(input$step3_plot_line_2, {
		p = plot_comb_o2m(
			data1=merge_data_line(), data2=comp_data_line(),
			x_name=input$x_name, title_name=input$title_name,
			group_1_color_2=input$group_1_color_2, group_2_color_2=input$group_2_color_2,
			axis_size=input$axis_size, title_size=input$title_size,
			significance=input$significance, label_size=input$label_size,
			custom_theme=themes_list[[input$theme]]
		)
		return(p)
	})


	output$comp_plot_line = renderPlot({comp_plot_line()})

	# Download results
	observeEvent(input$step3_plot_line_2,{
		res1 = comp_plot_line()
		res2 = merge_data_line()
		p_comp = comp_data_line()
		p_comp$identifier = unique(merge_data_line()$id)
		p_comp$phenotype = unique(merge_data_line()$phenotype)	
		p_comp$group_1 = levels(merge_data_line()$group)[1]
		p_comp$group_2 = levels(merge_data_line()$group)[2]
		res3 = p_comp
		callModule(download_res_Server, "download_res2comp", res1, res2, res3)
	})
}