
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
				
		ErrorInfo = ErrorInfo();
		
		StandardProcessing = True;
		
		If AdditionalParameters.ErrorNotifyDescription <> Undefined Then
			ExecuteNotifyProcessing(AdditionalParameters.ErrorNotifyDescription, ErrorInfo); 
		Else
			Raise;
		EndIf; 
		
	EndTry;
	
EndProcedure

Procedure ErrorHandler(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	
	If AdditionalParameters.ErrorHandler <> Undefined Then
		
		ExecuteNotifyProcessing(AdditionalParameters.ErrorHandler, ErrorInfo);
			
		StandardProcessing = False;
	
	EndIf; 
	
EndProcedure

#Region Stages

Procedure StageShowFileDialog(Context, AdditionalParameters) Export
	
	PrepareStageParameters(AdditionalParameters, Context.Continuation, 2);
	
	ShowFileDialogWrapper = New NotifyDescription(
		"ShowFileDialogWrapper",
		ThisObject,
		AdditionalParameters
	);
	
	BeginWithFileSystemExtension(ShowFileDialogWrapper);
	
EndProcedure

Procedure StageBeginCreatingDirectory(Context, AdditionalParameters) Export
	
	PrepareStageParameters(AdditionalParameters, Context.Continuation, 2);
		
	BeginCreatingDirectoryWrapper = New NotifyDescription(
		"BeginCreatingDirectoryWrapper",
		ThisObject,
		AdditionalParameters
	);
	
	BeginWithFileSystemExtension(BeginCreatingDirectoryWrapper);
		
EndProcedure 

Procedure StageBeginDeletingFiles(Context, AdditionalParameters) Export
	
	PrepareStageParameters(AdditionalParameters, Context.Continuation, 1);
		
	BeginDeletingFilesWrapper = New NotifyDescription(
		"BeginDeletingFilesWrapper",
		ThisObject,
		AdditionalParameters
	);
	
	BeginWithFileSystemExtension(BeginDeletingFilesWrapper);
		
EndProcedure

Procedure StageStopPipeline(Context, AdditionalParameters) Export
	
	If Context.Continuation <> Undefined Then
		Raise "violation of protocol";
	EndIf; 
	
	If AdditionalParameters.ParentPiplineContinuation <> Undefined Then
		PipelineNotifyProcessingClient.Invoke(AdditionalParameters.ParentPiplineContinuation, "PipelineNotifyProcessingInternalClient.StageStopPipeline()");
	EndIf; 
	
EndProcedure

#EndRegion // Stages

#Region AttachingFileSystemExtension

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
		"PipelineNotifyProcessingInternalClient.EmptyProcedure1()"
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
		"PipelineNotifyProcessingInternalClient.EmptyProcedure2()"
	);
	
EndProcedure

#EndRegion // EmptyProcedureDescriptions

#Region Wrappers

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

Procedure CustomStageDecorator(Context, AdditionalParameters) Export
	
	ExecuteNotifyProcessing(AdditionalParameters.NotifyDescription, Context); // TODO: может быть не Context?
	
	PipelineNotifyProcessingClient.Invoke(Context.Continuation, "PipelineNotifyProcessingInternalClient.CustomStageDecorator");
	
EndProcedure 

#EndRegion // Decorators

#EndRegion // Public

#Region Private

Procedure PrepareStageParameters(AdditionalParameters, Continuation, NumberOfCallbackParameters)
	
	If AdditionalParameters.NotifyDescription = Undefined Then
		
		If NumberOfCallbackParameters = 1 Then
			AdditionalParameters.NotifyDescription = PipelineNotifyProcessingInternalClient.EmptyProcedure1NotifyDescription();
		ElsIf NumberOfCallbackParameters = 2 Then
			AdditionalParameters.NotifyDescription = PipelineNotifyProcessingInternalClient.EmptyProcedure2NotifyDescription();
		Else
			Raise "violation of protocol"
		EndIf;
		
	EndIf;
	
	NotifyDescriptionParameters = AdditionalParameters.NotifyDescription.AdditionalParameters;
	NotifyDescriptionParameters.Insert("Continuation", Continuation);
	NotifyDescriptionParameters.Insert("ErrorHandler", AdditionalParameters.ErrorHandler);
	
EndProcedure

#EndRegion // Private