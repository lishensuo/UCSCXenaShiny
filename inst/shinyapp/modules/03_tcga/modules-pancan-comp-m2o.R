ui.modules_pancan_comp_m2o = function(id) {
	ns = NS(id)
	fluidPage(
		# 第一行：选择肿瘤及样本
		fluidRow(
			# 选择分组依据
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

					h4(strong("S1.2 Choose cancer")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Cancer types", 
					                   content = "tcga_types"),
					pickerInput(
						ns("choose_cancer"), NULL,
						choices = sort(tcga_names),
						selected = "BRCA"),
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
					add_signature_UI(ns("add_signature2comp"), database = "toil"),				
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
					h4(strong("S2.2 Get batch data for comparison")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Get batch data", 
					                   content = "get_batch_data"),  
					# 批量数据下载
					multi_upload_UI(ns("multi_upload2comp"),"Query", database = "toil"),

				)
			),
			column(
				5,
				wellPanel(
					style = "height:1100px",
					h2("S3: Analyze", align = "center") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Analyze", 
					                   content = "analyze_comp_3"),  
					h4(strong("S3.1 Set analysis parameters")), 
					# br(),br(),
					# h4("1. Set method"),
					selectInput(ns("comp_method"), "Comparison method:",choices = c("wilcox.test", "t.test"),selected="wilcoxon"),
					shinyWidgets::actionBttn(
						ns("cal_batch_comp"), "Run",
				        style = "gradient",
				        icon = icon("table"),
				        color = "primary",
				        block = TRUE,
				        size = "sm"
					),
					br(),br(),
					fluidRow(
						column(10, offset = 1,
							   div(uiOutput(ns("comp_stat_tb.ui")),style = "height:600px"),
							   )
					),
					h4(strong("S3.2 Download results")), 
					# uiOutput(ns("comp_stat_dw.ui"))
					download_res_UI(ns("download_res2comp"))
				)
			)
		)
	)
}


server.modules_pancan_comp_m2o = function(input, output, session) {
	ns <- session$ns


	# 记录选择癌症
	cancer_choose <- reactiveValues(database = "toil",name = "BRCA", filter_phe_id=NULL,
		phe_primary=query_tcga_group(cancer = "BRCA", return_all = T))
	observe({
		cancer_choose$name = input$choose_cancer
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


	# 设置分组
	group_final = callModule(group_samples_Server, "group_samples2comp",
					   	   database = "toil",
						   cancers=reactive(cancer_choose$name),
						   samples=reactive(cancer_choose$filter_phe_id),
						   custom_metadata=reactive(custom_meta_sig()),
						   opt_pancan = reactive(opt_pancan())
						   )

	# 批量下载数据
	L3s_x_data =  callModule(multi_upload_Server, "multi_upload2comp", 
							 database = "toil",
							 samples=reactive(cancer_choose$filter_phe_id),
							 custom_metadata=reactive(custom_meta_sig()),
						     opt_pancan = reactive(opt_pancan()),
						     table.ui = FALSE
							 )
	L3s_x = reactive({
		unique(L3s_x_data()$id)
	})

	## 比较分析
	comp_stat = eventReactive(input$cal_batch_comp, {
		shiny::validate(
			need(try(nrow(group_final())>0), 
				"Please inspect whether to set groups in S2 step."),
		)
		shinyjs::disable("cal_batch_comp")
		withProgress(message = "Please wait for a while.",{
			comp_stat = lapply(seq(L3s_x()), function(i){
				# i = 1
			    incProgress(1 / length(L3s_x()), detail = paste0("(Finished ",i,"/",length(L3s_x()),")"))

				L3_x = L3s_x()[i]

				y_data = L3s_x_data() %>%
					dplyr::filter(id == L3_x) %>% 
					dplyr::select(Sample, value)

				group_data = group_final()[,c(1,3,4)]
				colnames(group_data) = c("Sample","group","phenotype")
				data = dplyr::inner_join(y_data, group_data) %>%
					dplyr::select(Sample, value, group, everything()) %>% na.omit()
				# 检查数据是否合理
				if(nrow(data)==0 | sd(data$value)==0) return(c(NaN, NaN, NaN))
				if(length(unique(data$group))==1 | min(table(data$group))<3) return(c(NaN, NaN, NaN))
				
				if(input$comp_method == "t.test"){
					comp_obj = t.test(value ~ group, data)
				} else if (input$comp_method == "wilcox.test"){
					comp_obj = wilcox.test(value ~ group, data)
				}
				means = data %>%
				  dplyr::group_by(group) %>% 
				  dplyr::summarise(value=mean(value)) %>% 
				  dplyr::pull(value)

				comp_res = c(means, comp_obj$p.value)
				comp_res
			}) %>% do.call(rbind, .) %>% as.data.frame()

			colnames(comp_stat) = c(levels(group_final()$group),"p.value")
			comp_stat = comp_stat %>% 
			  dplyr::mutate(id = L3s_x(), .before = 1) %>%
			  dplyr::arrange(p.value)
			comp_stat
		})
		shinyjs::enable("cal_batch_comp")
		comp_stat
	})

	output$comp_stat_tb.ui = renderUI({
		output$comp_stat_tb = renderDataTable({
			# comp_stat()
			comp_stat_ = comp_stat() %>%
				dplyr::rename("Batch identifiers"="id")
			comp_stat_$p.value = format(comp_stat_$p.value, scientific=T, digits = 3)
			dt = datatable(comp_stat_,
				# class = "nowrap row-border",
				options = list(pageLength = 10, 
					columnDefs = list(
						list(className = 'dt-center', targets="_all"),
						list(orderable=TRUE, targets = 0)))
			) %>%
				formatRound(columns = levels(group_final()$group), digits = 3)
			dt$x$data[[1]] <- as.numeric(dt$x$data[[1]]) 
			dt
		}) 
	dataTableOutput(ns("comp_stat_tb"))
	})

	# Download results
	observeEvent(input$cal_batch_comp,{
		res1 = NULL
		group_data = group_final()[,c(1,3,4)]
		colnames(group_data) = c("Sample","group","phenotype")
		res2 = L3s_x_data() %>%
			dplyr::inner_join(group_data) %>% na.omit()
		res3 = comp_stat()
		callModule(download_res_Server, "download_res2comp", res1, res2, res3)
	})
}