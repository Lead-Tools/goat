
// Copyright 2019 Tsukanov Alexander. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#Region Public

Procedure ExecuteStage(Context, AdditionalParameters) Export
	
	Try
		
		If Context.CallerName = Undefined Then
			Raise "violation of protocol"
		EndIf; 
		
		Message(StrTemplate("Caller(%1) -> Stage(%2)", Context.CallerName, AdditionalParameters.NotifyDescription.ProcedureName));
		
		Context.Continuation = AdditionalParameters.ContinuationNotifyDescription;
		
		FixedContext = New FixedStructure(Context);
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescription, FixedContext);
				
	Except
		
		ErrorContext = ErrorContext(ErrorInfo(), Context.AdditionalParameters);
		
		StandardProcessing = True;
		
		If AdditionalParameters.ErrorNotifyDescription <> Undefined Then
			ExecuteNotifyProcessing(AdditionalParameters.ErrorNotifyDescription, ErrorContext); 
		Else
			Raise;
		EndIf; 
		
	EndTry;
	
EndProcedure

Procedure ErrorHandler(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	
	If AdditionalParameters.ErrorHandler <> Undefined Then
		
		ErrorContext = ErrorContext(ErrorInfo, AdditionalParameters.AdditionalParameters);
		
		ExecuteNotifyProcessing(AdditionalParameters.ErrorHandler, ErrorContext);
			
		StandardProcessing = False;
	
	EndIf; 
	
EndProcedure

#Region Stages

// Реализация стандартных этапов

Procedure StageRunPipeline(Context, StageParameters) Export
	
	PipelineNotifyProcessingClient.RunPipeline(
		StageParameters.Stages,
		StageParameters.ErrorHandler,
		Context.Continuation,
		Context.CallerName,
		Context.AdditionalParameters
	);
	
EndProcedure

Procedure StageShowFileDialog(Context, StageParameters) Export
	
	PrepareStageParameters(StageParameters, Context.Continuation, 2, Context.AdditionalParameters);
	
	ShowFileDialogWrapper = New NotifyDescription(
		"ShowFileDialogWrapper",
		ThisObject,
		StageParameters
	);
	
	BeginWithFileSystemExtension(ShowFileDialogWrapper);
	
EndProcedure

Procedure StageBeginCreatingDirectory(Context, StageParameters) Export
	
	PrepareStageParameters(StageParameters, Context.Continuation, 2, Context.AdditionalParameters);
		
	BeginCreatingDirectoryWrapper = New NotifyDescription(
		"BeginCreatingDirectoryWrapper",
		ThisObject,
		StageParameters
	);
	
	BeginWithFileSystemExtension(BeginCreatingDirectoryWrapper);
		
EndProcedure 

Procedure StageBeginDeletingFiles(Context, StageParameters) Export
	
	PrepareStageParameters(StageParameters, Context.Continuation, 1, Context.AdditionalParameters);
		
	BeginDeletingFilesWrapper = New NotifyDescription(
		"BeginDeletingFilesWrapper",
		ThisObject,
		StageParameters
	);
	
	BeginWithFileSystemExtension(BeginDeletingFilesWrapper);
		
EndProcedure

Procedure StageStopPipeline(Context, Continuation) Export
	
	If Context.Continuation <> Undefined Then
		Raise "violation of protocol";
	EndIf; 
	
	PipelineNotifyProcessingClient.Invoke(Continuation, "PipelineNotifyProcessingInternalClient.StageStopPipeline()", Context.AdditionalParameters);
	
EndProcedure

#EndRegion // Stages

#Region AttachingFileSystemExtension

// Обвязка для выполнения процедур, требующих расширения для работы с файлами.
// Если расширение подключено, то процедура выполняется,
// в противном случае задается вопрос об установке расширения.

Procedure BeginWithFileSystemExtension(NotifyDescription) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotifyDescription", NotifyDescription);
	
	BeginAttachingFileSystemExtensionCallback = New NotifyDescription(
		"BeginAttachingFileSystemExtensionCallback",
		ThisObject,
		AdditionalParameters	
	);
	
	BeginAttachingFileSystemExtension(BeginAttachingFileSystemExtensionCallback)
	
EndProcedure

Procedure BeginAttachingFileSystemExtensionCallback(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Attached = Result;
	
	If Attached Then
		
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescription);
		
	Else
		
		QuestionText = NStr(
			"ru = 'Требуется установка расширения для работы с файлами. Продолжить?' ;
			|en = 'File system extension needs to be installed. Continue?'"
		);
		
		InstallFileSystemExtensionQuestionCallback = New NotifyDescription(
			"InstallFileSystemExtensionQuestionCallback",
			ThisObject,
			AdditionalParameters
		);
		
		ShowQueryBox(InstallFileSystemExtensionQuestionCallback, QuestionText, QuestionDialogMode.YesNo);
		
	EndIf;

EndProcedure 

Procedure InstallFileSystemExtensionQuestionCallback(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	QuestionDialogReturnCode = Result;
	
	If QuestionDialogReturnCode = DialogReturnCode.Yes Then
	
		BeginInstallFileSystemExtensionCallback = New NotifyDescription(
			"BeginInstallFileSystemExtensionCallback",
			ThisObject,
			AdditionalParameters
		);
		
		BeginInstallFileSystemExtension(BeginInstallFileSystemExtensionCallback);
	
	EndIf; 
	
EndProcedure

Procedure BeginInstallFileSystemExtensionCallback(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Installed = Result;
	
	If Installed Then
		
 		BeginAttachingFileSystemExtensionCallback = New NotifyDescription(
			"BeginAttachingFileSystemExtensionCallback", 
			ThisObject,
			AdditionalParameters
		);
		
		BeginAttachingFileSystemExtension(BeginAttachingFileSystemExtensionCallback);
				
	EndIf;
	
EndProcedure

#EndRegion // AttachingFileSystemExtension

#Region EmptyProcedureDescriptions

// Пустые процедуры-заглушки, которые используются в стандартных этапах в качестве коллбэка если он не указан.

Function EmptyProcedure1NotifyDescription() Export
	
	AdditionalParameters = New Structure;
	Return New NotifyDescription(
		"EmptyProcedure1",
		ThisObject,
		AdditionalParameters,
		"ErrorHandler",
		ThisObject
	);
	
EndFunction

Procedure EmptyProcedure1(AdditionalParameters) Export
	
	PipelineNotifyProcessingClient.Invoke(
		AdditionalParameters.Continuation,
		"PipelineNotifyProcessingInternalClient.EmptyProcedure1()",
		AdditionalParameters.AdditionalParameters
	);
	
EndProcedure

Function EmptyProcedure2NotifyDescription() Export
	
	AdditionalParameters = New Structure;
	Return New NotifyDescription(
		"EmptyProcedure2",
		ThisObject,
		AdditionalParameters,
		"ErrorHandler",
		ThisObject
	);
	
EndFunction

Procedure EmptyProcedure2(Result, AdditionalParameters) Export
	
	PipelineNotifyProcessingClient.Invoke(
		AdditionalParameters.Continuation,
		"PipelineNotifyProcessingInternalClient.EmptyProcedure2()",
		AdditionalParameters.AdditionalParameters
	);
	
EndProcedure

#EndRegion // EmptyProcedureDescriptions

#Region Wrappers

// Простые обертки, чтобы иметь возможность делать вызов через ExecuteNotifyProcessing()

Procedure ShowFileDialogWrapper(Result, AdditionalParameters) Export
		
	FileDialog = AdditionalParameters.FileDialog;
	FileDialog.Show(AdditionalParameters.NotifyDescription);	
	
EndProcedure

Procedure BeginDeletingFilesWrapper(Result, AdditionalParameters) Export
		
	BeginDeletingFiles(AdditionalParameters.NotifyDescription, AdditionalParameters.Path, AdditionalParameters.Mask);	
	
EndProcedure

Procedure BeginCreatingDirectoryWrapper(Result, AdditionalParameters) Export
		
	BeginCreatingDirectory(AdditionalParameters.NotifyDescription, AdditionalParameters.DirectoryName);	
	
EndProcedure

#EndRegion // Wrappers

#Region Decorators

// Декораторы, которые расширяют логику пользовательских процедур.
// Например, добавляют в конце передачу управления на следующий этап конвейера.

Procedure CustomStageDecorator(Context, AdditionalParameters) Export
	
	ExecuteNotifyProcessing(AdditionalParameters.NotifyDescription, Context);
	
	PipelineNotifyProcessingClient.Invoke(Context.Continuation, "PipelineNotifyProcessingInternalClient.CustomStageDecorator", Context.AdditionalParameters);
	
EndProcedure 

Procedure CustomCallbackDecorator(Result, AdditionalParameters) Export
	
	ExecuteNotifyProcessing(AdditionalParameters.NotifyDescription, Result);
	
	PipelineNotifyProcessingClient.Invoke(AdditionalParameters.Continuation, "PipelineNotifyProcessingInternalClient.CustomStageCallback", AdditionalParameters.AdditionalParameters);
	
EndProcedure

#EndRegion // Decorators

#EndRegion // Public

#Region Private

// Общая подготовка параметров этапа
// StageParameters - парметры этапа
// Continuation - обработчик следующего этапа
// NumberOfCallbackParameters - количество параметров коллбэка
// AdditionalParameters - дополнительный параметр который передается этапу в Context.AdditionalParameters
Procedure PrepareStageParameters(StageParameters, Continuation, NumberOfCallbackParameters, AdditionalParameters)
	
	If StageParameters.NotifyDescription = Undefined Then
		
		If NumberOfCallbackParameters = 1 Then
			StageParameters.NotifyDescription = PipelineNotifyProcessingInternalClient.EmptyProcedure1NotifyDescription();
		ElsIf NumberOfCallbackParameters = 2 Then
			StageParameters.NotifyDescription = PipelineNotifyProcessingInternalClient.EmptyProcedure2NotifyDescription();
		Else
			Raise "violation of protocol"
		EndIf;
		
	EndIf;
	
	// TODO: может быть переиграть это?
	
	// Дополнительная информация в AdditionalParameters коллбэков.
	// Например в StageShowFileDialog() будет подготовлена информация для передачи в CustomCallbackDecorator() 
	NotifyDescriptionParameters = StageParameters.NotifyDescription.AdditionalParameters;
	NotifyDescriptionParameters.Insert("Continuation", Continuation); // см. например CustomCallbackDecorator() или EmptyProcedure2()
	NotifyDescriptionParameters.Insert("AdditionalParameters", AdditionalParameters); // см. например CustomCallbackDecorator() или EmptyProcedure2()
	NotifyDescriptionParameters.Insert("ErrorHandler", StageParameters.ErrorHandler); // см. например ErrorHandler()
	
EndProcedure

Function ErrorContext(ErrorInfo, AdditionalParameters)
	
	ErrorContext = New Structure;
	ErrorContext.Insert("ErrorInfo", ErrorInfo);
	ErrorContext.Insert("AdditionalParameters", AdditionalParameters);
	
	Return ErrorContext;
	
EndFunction 

#EndRegion // Private