
&AtClient
Procedure TestSync(Command)
	
	ClearMessages();
	
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
	//                       * второй конвейер запускается на втором этапе первого конвейра;
	//                       * отступом выделен вложенный конвейер (второй);
	//                       * этапы пронумерованы по уровням)
	// --------------------------------------------------------------------------------------
	// 1. Показать диалог выбора каталога
	// 2. Выполнить вложенный конвейер:
	//     2.1 Создать папку
	//     2.2 Создать подпапку (при ошибке переход на этап 2.5)
	//     2.3 Удалить подпапку
	//     2.4 Вывести "Success"
	//     2.5 Вывести "Tail1" (после этого этапа происходит переход на этап 2)
	// 3. Вывести "Tail2"
	
	ClearMessages();
	
	#Region FileDialog
	
	FileOpenDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	FileOpenDialog.Directory = "";
	FileOpenDialog.FullFileName = "";
	Filter = NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files(*.*)|*.*'");
	FileOpenDialog.Filter = Filter;
	FileOpenDialog.Multiselect = False;
	FileOpenDialog.Title = NStr("ru = 'Выберите каталог'; en = 'Select the folder'");
	
	#EndRegion // FileDialog
	
	Pnp = PipelineNotifyProcessingClient;
	
	// Ящик, который двигается по конвейеру через все этапы (см. Context.AdditionalParameters)
	Box = New Structure;
	
	// Обработчик ошибок, возникших на конвейере
	ErrorHandler = Pnp.ErrorHandler("ErrorHandler", ThisObject);
	
	DirectoryName = "";
	
	// Список этапов конвейера
	Stages = New Array;
	
	// Список этапов вложенного конвейера
	NestedStages = New Array;
	Box.Insert("NestedStages", NestedStages);
	
	// 1. Стандартный этап для выбора файла/каталога в стандартном диалоге
	ShowFileDialogCallback = Pnp.CustomCallback("ShowFileDialogCallback", ThisObject, Box);
	Stages.Add(Pnp.StageShowFileDialog(ShowFileDialogCallback, FileOpenDialog));
		
	// 2. Стандартный этап для запуска вложенного конвейра
	Stages.Add(Pnp.StageRunPipeline(NestedStages, ErrorHandler));
		
	// 3. Пользовательский этап
	Stages.Add(Pnp.CustomStage("StageTail2", ThisObject, Undefined));
	
	// Запуск конвейера
	Pnp.RunPipeline(Stages, ErrorHandler, Undefined, "DataProcessor.Test.Form.TestAsync", Box);
	
EndProcedure

&AtClient
Procedure ShowFileDialogCallback(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;		
	EndIf;
	
	DirectoryName = Result[0];
	
	AdditionalParameters.Insert("DirectoryName", DirectoryName);
	
	NestedStages = AdditionalParameters.NestedStages;
	
	Pnp = PipelineNotifyProcessingClient;
		
	ErrorHandler = Pnp.ErrorHandler("ErrorHandler", ThisObject);
	
	// Список этапов конвейера
		
	// 2.1 Стандартный этап для создания каталога
	NestedStages.Add(Pnp.StageBeginCreatingDirectory(Undefined, DirectoryName));
	
	// 2.2 Стандартный этап для создания каталога
	NestedStages.Add(Pnp.StageBeginCreatingDirectory(Undefined, DirectoryName + "AccessVerification\", ErrorHandler));
	
	// 2.3 Стандартный этап для удаления каталога	
	NestedStages.Add(Pnp.StageBeginDeletingFiles(Undefined, DirectoryName + "AccessVerification\", Undefined));
	
	// 2.4 Пользовательский этап	
	StageParameters = New Structure;
	StageParameters.Insert("DirectoryName", DirectoryName);
	NestedStages.Add(Pnp.CustomStage("StageSuccess", ThisObject, StageParameters));
	
	// 2.5 Пользовательский этап
	NestedStages.Add(Pnp.CustomStage("StageTail1", ThisObject, Undefined));
		
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
Procedure ErrorHandler(ErrorContext, AdditionalParameters) Export
	
	// no rights for directory creation

	Message(StrTemplate("Error: Text = ""%1""; DirectoryName = ""%2""", BriefErrorDescription(ErrorContext.ErrorInfo), ErrorContext.AdditionalParameters.DirectoryName));
		
	// Передача управления на предпоследний этап
	Continuation = AdditionalParameters.StageHandlers[AdditionalParameters.StageHandlers.UBound() - 1];
	PipelineNotifyProcessingClient.Invoke(Continuation, "DataProcessor.Test.Form.ErrorHandler", ErrorContext.AdditionalParameters);
	
EndProcedure
