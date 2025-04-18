ui.modules_pancan_cor_m2o = function(id) {
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
					custom_meta_UI(ns("custom_meta2cor_batch")),
					br(),

					h4(strong("S1.5 Add signature"),"[opt]") %>% 
						helper(type = "markdown", size = "m", fade = TRUE, 
					                   title = "Add signature", 
					                   content = "add_signature"),
					add_signature_UI(ns("add_signature2cor"), database = "toil"),
				)
			),
			column(
				4,
				wellPanel(
					style = "height:1100px",
					h2("S2: Get data", align = "center"),
					# 批量数据下载
					h4(strong("S2.1 Get batch data for X-axis")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Get batch data", 
					                   content = "get_batch_data"), 
					multi_upload_UI(ns("multi_upload2cor"),button_name = "Query", database = "toil"),
					# br(),br(),
					# 单项数据下载
					h4(strong("S2.2 Get data for Y-axis")) %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Get one data", 
					                   content = "get_one_data"), 
					download_feat_UI(ns("download_y_axis"), button_name="Query", database = "toil")
				)
			),
			column(
				5,
				wellPanel(
					style = "height:1100px",
					h2("S3: Analyze", align = "center") %>% 
						helper(type = "markdown", size = "l", fade = TRUE, 
					                   title = "Analyze", 
					                   content = "analyze_cor_3"),  

					h4(strong("S3.1 Set analysis parameters")), 
					selectInput(ns("cor_method"),"Correlation method:",choices = c("spearman","pearson"), selected="Spearman"),
					shinyWidgets::actionBttn(
						ns("cal_batch_cor"), "Run",
				        style = "gradient",
				        icon = icon("table"),
				        color = "primary",
				        block = TRUE,
				        size = "sm"
					),
					br(),br(),
					fluidRow(
						column(10, offset = 1,
							   div(uiOutput(ns("cor_stat_tb.ui")),style = "height:600px"),
							   )
					),
					h4(strong("S3.2 Download results")), 
					download_res_UI(ns("download_res2cor"))
				)
			)
		)
	)
}


server.modules_pancan_cor_m2o = function(input, output, session) {
	ns <- session$ns

	# 记录选择癌症
	cancer_choose <- reactiveValues(name = "BRCA", filter_phe_id=NULL,
		phe_primary=query_tcga_group(database = "toil", cancer = "BRCA", return_all = T))
	observe({
		cancer_choose$name = input$choose_cancer
		cancer_choose$phe_primary <- query_tcga_group(database = "toil", cancer = cancer_choose$name, return_all = T)
	})

	# 自定义上传metadata数据
	custom_meta = callModule(custom_meta_Server, "custom_meta2cor_batch", database = "toil")
	# signature
	sig_dat = callModule(add_signature_Server, "add_signature2cor", database = "toil")

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


	# 批量下载数据
	L3s_x_data =  callModule(multi_upload_Server, "multi_upload2cor", 
							 database = "toil",
							 samples=reactive(cancer_choose$filter_phe_id),
							 custom_metadata=reactive(custom_meta_sig()),
						     opt_pancan = reactive(opt_pancan())
							 )
	L3s_x = reactive({
		unique(L3s_x_data()$id)
	})

	L3_y_data = callModule(download_feat_Server, "download_y_axis", 
							 database = "toil",
							 samples=reactive(cancer_choose$filter_phe_id),
							 custom_metadata=reactive(custom_meta_sig()),
						     opt_pancan = reactive(opt_pancan()),
						     check_numeric=TRUE							 )

	# 相关性分析
	cor_stat = eventReactive(input$cal_batch_cor,{
		shinyjs::disable("cal_batch_cor")
		x_datas = L3s_x_data()[,c("id","Sample","value")]
		colnames(x_datas)[c(1,3)] = paste0("x_",colnames(x_datas)[c(1,3)])
		y_data = L3_y_data()[,c("id","Sample","value")]
		colnames(y_data)[c(1,3)] = paste0("y_",colnames(y_data)[c(1,3)])

		withProgress(message = "Please wait for a while.",{
			cor_stat = lapply(seq(L3s_x()), function(i) {	
				L3_x = L3s_x()[i]
				xy_data = x_datas %>%
					dplyr::filter(x_id == L3_x) %>%
					dplyr::inner_join(y_data) %>% as.data.frame()
				if(nrow(na.omit(xy_data))<3){return(c(NaN, NaN))}
			    cor_obj = cor.test(xy_data[,"x_value"],xy_data[,"y_value"],
			                       method = input$cor_method)
			    incProgress(1 / length(L3s_x()), detail = paste0("(Finished ",i,"/",length(L3s_x()),")"))
			   	return(c(cor_obj$p.value, cor_obj$estimate))
			}) %>% do.call(rbind, .) %>% as.data.frame()
			colnames(cor_stat) = c("p.value","R")
			cor_stat2 = cor_stat %>% 
			  dplyr::select(R, p.value) %>% 
			  dplyr::mutate(id.x = L3s_x(), .before = 1) %>% 
			  dplyr::mutate(id.y = input$L3_y, .before = 2) %>%
			  dplyr::arrange(p.value)
			cor_stat2
		})
		shinyjs::enable("cal_batch_cor")
		cor_stat2
	})


	output$cor_stat_tb.ui = renderUI({
		output$cor_stat_tb = renderDataTable({
			cor_stat_ = cor_stat() %>%
				dplyr::rename("Batch identifiers"="id.x")
			cor_stat_$p.value = format(cor_stat_$p.value, scientific=T, digits = 3)
			dt = datatable(cor_stat_,
				# class = "nowrap row-border",
				options = list(pageLength = 10, 
					columnDefs = list(
						list(className = 'dt-center', targets="_all"),
						list(orderable=TRUE, targets = 0)))
			) %>%
				formatRound(columns = c("R"), digits = 3)
			dt$x$data[[1]] <- as.numeric(dt$x$data[[1]]) 
			dt
		}) 
	dataTableOutput(ns("cor_stat_tb"))
	})

	# Download results
	observeEvent(input$cal_batch_cor,{
		res1 = NULL
		x_datas = L3s_x_data() %>%
			dplyr::mutate(axis = "X")
		y_data = L3_y_data() %>%
			dplyr::select(id, Sample, value) %>%
			dplyr::mutate(axis = "Y")
		res2 = rbind(x_datas, y_data)
		res3 = cor_stat()
		callModule(download_res_Server, "download_res2cor", res1, res2, res3)
	})
}
