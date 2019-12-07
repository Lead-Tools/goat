
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
	
	// Структура конвейеров (* два конвейера;
	//                       * второй конвейер запускается на первом этапе первого конвейра;
	//                       * отступом выделен вложенный конвейер (второй);
	//                       * этапы пронумерованы по уровням)
	// --------------------------------------------------------------------------------------
	// 1. Показать диалог выбора каталога
	//     1.1 Создать папку (при ошибке переход на этап 1.5)
	//     1.2 Создать подпапку (при ошибке переход на этап 1.5)
	//     1.3 Удалить подпапку (при ошибке переход на этап 1.5)
	//     1.4 Вывести "Success"
	//     1.5 Вывести "Tail1" (после этого этапа происходит переход на этап 2)
	// 2. Вывести "Tail2"
	
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
	Stages.Add(Pnp.StageShowFileDialog(ShowFileDialogCallback, FileOpenDialog));
	
	// Пользовательский этап
	Stages.Add(Pnp.CustomStage("StageTail2", ThisObject, New Structure));
		
	#EndRegion // Stages
	
	// Обработчик ошибок, возникших на конвейере
	ErrorHandler = New NotifyDescription("ErrorHandler", ThisObject, New Structure);
	
	// Запуск конвейера
	Pnp.RunPipeline(Stages, ErrorHandler, Undefined, "DataProcessor.Test.Form.TestAsync");
	
EndProcedure

&AtClient
Procedure ShowFileDialogCallback(Result, AdditionalParameters) Export
	
	// AdditionalParameters.Continuation - это следующий этап родительского конвейера
	
	If Result = Undefined Then
		PipelineNotifyProcessingClient.Invoke(AdditionalParameters.Continuation, "DataProcessor.Test.Form.ShowFileDialogCallback:отказ");
		Return;		
	EndIf;
	
	DirectoryName = Result[0];
	
	Pnp = PipelineNotifyProcessingClient;
	
	// Обработчик ошибок, возникших на конвейере
	ErrorParameters = New Structure;
	ErrorParameters.Insert("DirectoryName", DirectoryName);
	ErrorParameters.Insert("ParentContinuation", AdditionalParameters.Continuation);
	ErrorHandler = New NotifyDescription("ErrorHandler", ThisObject, ErrorParameters);
	
	// Список этапов конвейера
	
	Stages = New Array;
	
	#Region Stages
	
	// Стандартный этап для создания каталога
	Stages.Add(Pnp.StageBeginCreatingDirectory(Undefined, DirectoryName));
	
	// Стандартный этап для создания каталога
	Stages.Add(Pnp.StageBeginCreatingDirectory(Undefined, DirectoryName + "AccessVerification\", ErrorHandler));
	
	// Стандартный этап для удаления каталога	
	Stages.Add(Pnp.StageBeginDeletingFiles(Undefined, DirectoryName + "AccessVerification\", Undefined));
	
	// Пользовательский этап	
	StageParameters = New Structure;
	StageParameters.Insert("DirectoryName", DirectoryName);
	Stages.Add(Pnp.CustomStage("StageSuccess", ThisObject, StageParameters));
	
	// Пользовательский этап
	Stages.Add(Pnp.CustomStage("StageTail1", ThisObject, New Structure));
		
	#EndRegion // Stages
	
	// Запуск конвейера
	Pnp.RunPipeline(Stages, ErrorHandler, AdditionalParameters.Continuation, "DataProcessor.Test.Form.ShowFileDialogCallback");
	
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
Procedure ErrorHandler(ErrorInfo, AdditionalParameters) Export
	
	// no rights for directory creation, or this path is absent
	
	Message(StrTemplate("Error: Text = ""%1""; DirectoryName = ""%2""", BriefErrorDescription(ErrorInfo), AdditionalParameters.DirectoryName));
	
	// Передача управления на следующий этап родительского конвейера
	//PipelineNotifyProcessingClient.Invoke(AdditionalParameters.ParentContinuation, "DataProcessor.Test.Form.ErrorHandler");
	
	// Передача управления на предпоследний этап
	Continuation = AdditionalParameters.StageHandlers[AdditionalParameters.StageHandlers.UBound() - 1];
	PipelineNotifyProcessingClient.Invoke(Continuation, "DataProcessor.Test.Form.ErrorHandler");
	
EndProcedure
