
// Copyright 2019 Tsukanov Alexander. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#Region Public

// Строит и сразу запускает конвейер.
// Stages - массив этапов
// ErrorHandler - обработчик ошибок на всех этапах
// Continuation - обработчик этапа, которому будет передано управление по окончании конвейера (например для возврата в родительский конвейер)
// CallerName - Имя вызывающей процедуры (для отладки)
// AdditionalParameters - произвольные дополнительные параметры, которые будут передаваться каждому этапу в Context.AdditionalParameters
Procedure RunPipeline(Stages, ErrorHandler, Continuation, CallerName, AdditionalParameters) Export
	
	Pipeline = BuildNotifyProcessingPipeline(Stages, ErrorHandler, Continuation);
	
	Invoke(Pipeline, CallerName, AdditionalParameters);
	
EndProcedure 

// Строит конвейер (цепочку обработчиков этапов) из массива этапов.
// Stages - массив этапов
// ErrorHandler - обработчик ошибок на всех этапах
// Continuation - обработчик этапа, которому будет передано управление по окончании конвейера (например для возврата в родительский конвейер)
Function BuildNotifyProcessingPipeline(Stages, ErrorHandler, Continuation) Export 
	
	StageHandlers = New Array(Stages.Count() + 1); // + StageStopPipeline
	
	Index = Stages.Count();
	
	StageStopPipeline = New NotifyDescription(
		"StageStopPipeline",
		PipelineNotifyProcessingInternalClient,
		Continuation
	);
	
	NotifyDescription = StageHandler(StageStopPipeline, Undefined, ErrorHandler);
	StageHandlers[Index] = NotifyDescription;
	
	While Index > 0 Do
		Index = Index - 1;
		Stage = Stages[Index];
		StageParameters = Stage.AdditionalParameters;
		StageErrorHandler = Undefined;
		If StageParameters.Property("ErrorHandler", StageErrorHandler)
			And StageErrorHandler <> Undefined Then 
			StageErrorHandler.AdditionalParameters.Insert("StageHandlers", StageHandlers);
		EndIf; 
		NotifyDescription = StageHandler(Stage, NotifyDescription, ErrorHandler);
		StageHandlers[Index] = NotifyDescription;
	EndDo; 
		
	ErrorHandler.AdditionalParameters.Insert("StageHandlers", StageHandlers);
	
	Return NotifyDescription;
	
EndFunction 

// Запускает на выполнение обработчик этапа.
// StageHandler - обработчик этапа (см. StageHandler())
// CallerName - Имя вызывающей процедуры (для отладки)
// AdditionalParameters - произвольный параметр, который передается этапу в Context.AdditionalParameters
Procedure Invoke(StageHandler, CallerName, AdditionalParameters) Export
	
	Context = New Structure;
	Context.Insert("CallerName", CallerName);
	Context.Insert("AdditionalParameters", AdditionalParameters);
	Context.Insert("Continuation", Undefined);
	
	ExecuteNotifyProcessing(StageHandler, Context);
	
EndProcedure 

// Создает новый обработчик ошибок
Function ErrorHandler(ProcedureName, Module) Export
	
	Return New NotifyDescription(ProcedureName, Module, New Structure);
	
EndFunction 

// Пользовательский этап. По окончании управление сразу передается на следующий этап в конвейере.
// ProcedureName - имя процедуры, которая должна быть экспортной, на клиенте, и иметь два параметра: Context, AdditionalParameters
// Module - модуль, в котором находится процедура
// AdditionalParameters - произвольный параметр, который передается этапу в AdditionalParameters
Function CustomStage(ProcedureName, Module, AdditionalParameters = Undefined) Export
	
	NotifyDescription = New NotifyDescription(
		ProcedureName,
		Module,
		AdditionalParameters
	);
	
	DecoratorParameters = New Structure;
	DecoratorParameters.Insert("NotifyDescription", NotifyDescription);
	
	CustomStageDecorator = New NotifyDescription(
		"CustomStageDecorator",
		PipelineNotifyProcessingInternalClient,
		DecoratorParameters
	);	
	
	Return CustomStageDecorator;
	
EndFunction  

// Пользовательский коллбэк. По окончании управление сразу передается на следующий этап в конвейере.
// ProcedureName - имя процедуры, которая должна быть экспортной, на клиенте, и иметь два параметра: Result, AdditionalParameters
// Module - модуль, в котором находится процедура
// AdditionalParameters - произвольный параметр, который передается коллбэку в AdditionalParameters
Function CustomCallback(ProcedureName, Module, AdditionalParameters = Undefined) Export
	
	NotifyDescription = New NotifyDescription(
		ProcedureName,
		Module,
		AdditionalParameters
	);
	
	DecoratorParameters = New Structure;
	DecoratorParameters.Insert("NotifyDescription", NotifyDescription);
	
	CustomCallbackDecorator = New NotifyDescription(
		"CustomCallbackDecorator",
		PipelineNotifyProcessingInternalClient,
		DecoratorParameters
	);	
	
	Return CustomCallbackDecorator;
	
EndFunction

#Region Stages

Function StageRunPipeline(Stages, ErrorHandler = Undefined) Export
	
	StageParameters = New Structure;
	StageParameters.Insert("Stages", Stages);
	StageParameters.Insert("ErrorHandler", ErrorHandler);
	
	StageRunPipeline = New NotifyDescription(
		"StageRunPipeline",
		PipelineNotifyProcessingInternalClient,
		StageParameters
	);
	
	Return StageRunPipeline;
	
EndFunction

Function StageShowFileDialog(NotifyDescription, FileDialog, ErrorHandler = Undefined) Export
	
	StageParameters = New Structure;
	StageParameters.Insert("NotifyDescription", NotifyDescription);
	StageParameters.Insert("FileDialog", FileDialog);
	StageParameters.Insert("ErrorHandler", ErrorHandler);
	
	StageShowFileDialog = New NotifyDescription(
		"StageShowFileDialog",
		PipelineNotifyProcessingInternalClient,
		StageParameters
	);
	
	Return StageShowFileDialog;
	
EndFunction 

Function StageBeginCreatingDirectory(NotifyDescription, DirectoryName, ErrorHandler = Undefined) Export
	
	StageParameters = New Structure;
	StageParameters.Insert("NotifyDescription", NotifyDescription);
	StageParameters.Insert("DirectoryName", DirectoryName);
	StageParameters.Insert("ErrorHandler", ErrorHandler);
	
	StageBeginCreatingDirectory = New NotifyDescription(
		"StageBeginCreatingDirectory",
		PipelineNotifyProcessingInternalClient,
		StageParameters
	);
	
	Return StageBeginCreatingDirectory;
	
EndFunction 

Function StageBeginDeletingFiles(NotifyDescription, Path, Mask = Undefined, ErrorHandler = Undefined) Export
	
	StageParameters = New Structure;
	StageParameters.Insert("NotifyDescription", NotifyDescription);
	StageParameters.Insert("Path", Path);
	StageParameters.Insert("Mask", Mask);
	StageParameters.Insert("ErrorHandler", ErrorHandler);
	
	StageBeginDeletingFiles = New NotifyDescription(
		"StageBeginDeletingFiles",
		PipelineNotifyProcessingInternalClient,
		StageParameters
	);
	
	Return StageBeginDeletingFiles;
	
EndFunction

#EndRegion // Stages

#EndRegion //Public

#Region Private

// Создает новый обработчик этапа.
// NotifyDescription - этап, для которого нужно создать обработчик
// ContinuationNotifyDescription - следующий этап
// ErrorNotifyDescription - обработчик ошибок
Function StageHandler(NotifyDescription, ContinuationNotifyDescription, ErrorNotifyDescription)
		
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotifyDescription", NotifyDescription);
	AdditionalParameters.Insert("ContinuationNotifyDescription", ContinuationNotifyDescription);
	AdditionalParameters.Insert("ErrorNotifyDescription", ErrorNotifyDescription);
	
	ExecuteStage = New NotifyDescription(
		"ExecuteStage",
		PipelineNotifyProcessingInternalClient,
		AdditionalParameters
	);
	
	Return ExecuteStage;
	
EndFunction 

#EndRegion // Private