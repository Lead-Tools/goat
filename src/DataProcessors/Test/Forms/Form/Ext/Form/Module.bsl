
&AtClient
Procedure TestSync(Command)
	
	FileOpenDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	FileOpenDialog.Directory = "";
	FileOpenDialog.FullFileName = "";
	Filter = NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files(*.*)|*.*'");
	FileOpenDialog.Filter = Filter;
	FileOpenDialog.Multiselect = False;
	FileOpenDialog.Title = NStr("ru = 'Выберите каталог'; en = 'Select the folder'");
	
	If FileOpenDialog.Choose() Then
		
		DirectoryName = FileOpenDialog.Directory;
		
		// Create directory
		
		Try
			
			CreateDirectory(DirectoryName);
			CreateDirectory(DirectoryName + "AccessVerification\");
			DeleteFiles(DirectoryName + "AccessVerification\");
			
			Message("Success");
			
		Except
			
			// no rights for directory creation, or this path is absent
			
			Message("Error");
			
			Return;
			
		EndTry;
		
		Message("Tail1");
		
	EndIf;
	
	Message("Tail2");
	
EndProcedure

&AtClient
Procedure TestAsync(Command)
	
	Pnp = PipelineNotifyProcessingClient;
	
	// Список этапов конвейера
	
	Stages = New Array;
	
	#Region Stages
	
	#Region FileDialog
	
	FileOpenDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	FileOpenDialog.Directory = "";
	FileOpenDialog.FullFileName = "";
	Filter = NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files(*.*)|*.*'");
	FileOpenDialog.Filter = Filter;
	FileOpenDialog.Multiselect = False;
	FileOpenDialog.Title = NStr("ru = 'Выберите каталог'; en = 'Select the folder'");
	
	#EndRegion // FileDialog
	
	ShowFileDialogCallback = New NotifyDescription("ShowFileDialogCallback", ThisObject, New Structure);
	
	// Стандартный этап для выбора файла/каталога в стандартном диалоге
	StageShowFileDialog = Pnp.StageShowFileDialog(ShowFileDialogCallback, FileOpenDialog);
	Stages.Add(StageShowFileDialog);
	
	// Пользовательский этап
	StageTail2 = Pnp.CustomStage("StageTail2", ThisObject, New Structure);
	Stages.Add(StageTail2);
	
	// Стандартный этап для остановки конвейера
	StageStopPipeline = Pnp.StageStopPipeline(Undefined);
	Stages.Add(StageStopPipeline);
	
	#EndRegion // Stages
	
	// Обработчик ошибок, возникших на конвейере
	PipelineErrorHandler = New NotifyDescription("PipelineErrorHandler", ThisObject, New Structure);
	
	// Построение конвейера
	Pipeline = Pnp.BuildNotifyProcessingPipeline(Stages, PipelineErrorHandler);
	
	// Запуск конвейера
	Pnp.Invoke(Pipeline, "DataProcessor.Test.Form.TestAsync");
	
EndProcedure

&AtClient
Procedure ShowFileDialogCallback(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;		
	EndIf;
	
	DirectoryName = Result[0];
	
	Pnp = PipelineNotifyProcessingClient;
	
	// Обработчик ошибок, возникших на конвейере
	ErrorParameters = New Structure;
	ErrorParameters.Insert("DirectoryName", DirectoryName);
	ErrorParameters.Insert("ParentContinuation", AdditionalParameters.Continuation);
	PipelineErrorHandler = New NotifyDescription("PipelineErrorHandler", ThisObject, ErrorParameters);
	
	// Список этапов конвейера
	
	Stages = New Array;
	
	#Region Stages
	
	// Стандартный этап для создания каталога
	StageBeginCreatingDirectory = Pnp.StageBeginCreatingDirectory(Undefined, DirectoryName);
	Stages.Add(StageBeginCreatingDirectory);
	
	// Стандартный этап для создания каталога
	StageBeginCreatingDirectory = Pnp.StageBeginCreatingDirectory(Undefined, DirectoryName + "AccessVerification\", PipelineErrorHandler);
	Stages.Add(StageBeginCreatingDirectory);
	
	// Стандартный этап для удаления каталога	
	StageBeginDeletingFiles = Pnp.StageBeginDeletingFiles(Undefined, DirectoryName + "AccessVerification\", Undefined);
	Stages.Add(StageBeginDeletingFiles);
	
	// Пользовательский этап	
	StageParameters = New Structure;
	StageParameters.Insert("DirectoryName", DirectoryName);
	StageSuccess = Pnp.CustomStage("StageSuccess", ThisObject, StageParameters);
	Stages.Add(StageSuccess);
	
	// Пользовательский этап
	StageTail1 = Pnp.CustomStage("StageTail1", ThisObject, New Structure);
	Stages.Add(StageTail1);
	
	// Стандартный этап для остановки конвейера
	StageStopPipeline = Pnp.StageStopPipeline(AdditionalParameters.Continuation);
	Stages.Add(StageStopPipeline);
	
	#EndRegion // Stages
	
	// Построение конвейера
	Pipeline = Pnp.BuildNotifyProcessingPipeline(Stages, PipelineErrorHandler);
	
	// Запуск конвейера
	Pnp.Invoke(Pipeline, "DataProcessor.Test.Form.ShowFileDialogCallback");
	
EndProcedure

&AtClient
Procedure StageSuccess(Context, AdditionalParameters) Export
		
	Message("Success");
		
EndProcedure

&AtClient
Procedure StageTail1(Context, AdditionalParameters) Export
	
	Message("Tail1");
		
EndProcedure

&AtClient
Procedure StageTail2(Context, AdditionalParameters) Export
	
	Message("Tail2");
		
EndProcedure

&AtClient
Procedure PipelineErrorHandler(ErrorInfo, AdditionalParameters) Export
	
	// no rights for directory creation, or this path is absent
	
	Message(StrTemplate("Error: Text = ""%1""; DirectoryName = ""%2""", BriefErrorDescription(ErrorInfo), AdditionalParameters.DirectoryName));
	
	// Передача управления на следующий этап родительского конвейера
	//PipelineNotifyProcessingClient.Invoke(AdditionalParameters.ParentContinuation, "DataProcessor.Test.Form.PipelineErrorHandler");
	
	// Передача управления на предпоследний этап
	Continuation = AdditionalParameters.StageHandlers[AdditionalParameters.StageHandlers.UBound() - 1];
	PipelineNotifyProcessingClient.Invoke(Continuation, "DataProcessor.Test.Form.PipelineErrorHandler");
	
EndProcedure
