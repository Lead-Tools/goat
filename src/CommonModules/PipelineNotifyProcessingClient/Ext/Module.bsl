
#Region Public

Function BuildNotifyProcessingPipeline(NotifyProcessingList, ErrorHandler) Export
	
	If NotifyProcessingList.Count() = 0 Then
		Return PipelineNotifyProcessingInternalClient.EmptyProcedure2NotifyDescription();
	EndIf; 
	
	StageHandlers = New Array(NotifyProcessingList.Count());
	
	Index = NotifyProcessingList.UBound();
	
	NotifyDescription = StageHandler(NotifyProcessingList[Index], Undefined, ErrorHandler);
	StageHandlers[Index] = NotifyDescription;
	
	While Index > 0 Do
		Index = Index - 1;
		NotifyDescription = StageHandler(NotifyProcessingList[Index], NotifyDescription, ErrorHandler);
		StageHandlers[Index] = NotifyDescription;
	EndDo; 
	
	ErrorHandler.AdditionalParameters.Insert("StageHandlers", StageHandlers);
	
	Return NotifyDescription;
	
EndFunction 

Procedure Invoke(StageHandler, CallerName, AdditionalParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallerName", CallerName);
	Context.Insert("AdditionalParameters", AdditionalParameters);
	Context.Insert("Continuation", Undefined);
	
	ExecuteNotifyProcessing(StageHandler, Context);
	
EndProcedure 

Procedure ErrorHandler(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	
	PipelineNotifyProcessingInternalClient.ErrorHandler(ErrorInfo, StandardProcessing, AdditionalParameters);
	
EndProcedure

#Region Stages

Function StageShowFileDialog(NotifyDescription, FileDialog, ErrorHandler = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotifyDescription", NotifyDescription);
	AdditionalParameters.Insert("FileDialog", FileDialog);
	AdditionalParameters.Insert("ErrorHandler", ErrorHandler);
	
	StageShowFileDialog = New NotifyDescription(
		"StageShowFileDialog",
		PipelineNotifyProcessingInternalClient,
		AdditionalParameters
	);
	
	Return StageShowFileDialog;
	
EndFunction 

Function StageBeginCreatingDirectory(NotifyDescription, DirectoryName, ErrorHandler = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotifyDescription", NotifyDescription);
	AdditionalParameters.Insert("DirectoryName", DirectoryName);
	AdditionalParameters.Insert("ErrorHandler", ErrorHandler);
	
	StageBeginCreatingDirectory = New NotifyDescription(
		"StageBeginCreatingDirectory",
		PipelineNotifyProcessingInternalClient,
		AdditionalParameters
	);
	
	Return StageBeginCreatingDirectory;
	
EndFunction 

Function StageBeginDeletingFiles(NotifyDescription, Path, Mask = Undefined, ErrorHandler = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotifyDescription", NotifyDescription);
	AdditionalParameters.Insert("Path", Path);
	AdditionalParameters.Insert("Mask", Mask);
	AdditionalParameters.Insert("ErrorHandler", ErrorHandler);
	
	StageBeginDeletingFiles = New NotifyDescription(
		"StageBeginDeletingFiles",
		PipelineNotifyProcessingInternalClient,
		AdditionalParameters
	);
	
	Return StageBeginDeletingFiles;
	
EndFunction

Function StageStopPipeline(ParentPiplineContinuation) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ParentPiplineContinuation", ParentPiplineContinuation);
	
	StageStopPipeline = New NotifyDescription(
		"StageStopPipeline",
		PipelineNotifyProcessingInternalClient,
		AdditionalParameters
	);
	
	Return StageStopPipeline;
	
EndFunction 

#EndRegion // Stages

#EndRegion //Public

#Region Private

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