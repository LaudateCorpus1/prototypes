QuickSearch[] := DynamicModule[{index, input = "", result = ConstantArray["",5], type},
  index = SearchIndexObject["NotebookIndex"];
  Column[{
    InputField[Dynamic[input], String, ContinuousAction -> True],
    Dynamic[
      If[input =!= "",
        result = TextSearch[index, input, MaxItems -> 5];
        If[ result =!= $Failed,
          result = result[All];
          result = Map[
            Function[
              type = Part[FileNameSplit[#["ReferenceLocation"]], -2];
              Row[{type, " ", Hyperlink[#["Title"], #["ReferenceLocation"]]}] ],
              result
          ];
          result = PadRight[result,5,""],
          result = ConstantArray["",5]
        ];
      Column[result]
    ]]
  }]
];

file = FileNameJoin[{ ParentDirectory[$InputDirectoryName], "Icons", "click-to-copy.png" }];
icon := ( icon = Import[ file, "PNG" ] );


ClickToCopy[expr_] := ClickToCopy[expr,expr];

ClickToCopy[expr1_,expr2_] := DynamicModule[{},
  Button[
   Framed[Row[{" ", icon, " ", expr1}, Alignment -> Top],
    FrameMargins -> 2,
    RoundingRadius -> 1,
    FrameStyle -> {Thickness[0.45], Dashed, GrayLevel[0.8]}],
   CopyToClipboard[expr2], Appearance -> "Frameless"]];


BoxSyntaxQ[boxes_,form_:StandardForm] := Not[MatchQ[MakeExpression[boxes, form],_ErrorBox]];



Attributes[CopyAsBitmap] = {HoldAllComplete};
CopyAsBitmap[expr_] := Module[{nb},
  nb = CreateDocument[ExpressionCell[Defer[expr], "Input"],
    Visible -> True,
    WindowMargins -> {{-10000, Automatic}, {Automatic, -10000}}];
  SelectionMove[nb, All, Notebook];
  FrontEndExecute[
   FrontEndToken[InputNotebook[], "CopySpecial", "MGF"]];
  NotebookClose[nb];
  ];



  AddCodeCompletion[function_String][args___] := Module[{processed},
    processed = {args} /. {None -> 0, "AbsoluteFileName" -> 2,
       "RelativeFileName" -> 3, "Color" -> 4, "PackageName" -> 7,
       "DirectoryName" -> 8, "InterpreterType" -> 9};
    Function[FE`Evaluate[FEPrivate`AddSpecialArgCompletion[#]]][
     function -> processed]
    ]


(* Set some better options for the notebook interface *)
SetOptions[ $FrontEnd, SpellingOptions->{"AutoSpellCheckDelay" -> 0, "AutoSpellCheckPopupDelay" -> 0,"MaxSuggestions"->10}];


NotebookTranslate[nb_NotebookObject, opts___] := Module[{nbe},
  nbe = NotebookGet[nb];
  nbe = nbe /.
    Cell[s_String, args___] :>
     Cell[TextTranslation[s, opts ], args];
  NotebookPut[nbe]
  ]




(* Translation Cell *)

attach[selection_, tag_, label_, function_] := MathLink`CallFrontEnd[
  With[{buttonfunction = function},
   FrontEnd`AttachCell[
    selection,
    Cell[BoxData[
      ButtonBox[label, ButtonFunction :> buttonfunction,
       ButtonData -> tag, Appearance -> Automatic,
       Evaluator -> Automatic, Method -> "Queued"]], "Text"],
    {Automatic, {Left, Top}},
    {Right, Top},
    "ClosingActions" -> {"EvaluatorQuit"}]]];


buttonfunction1 = Function[{source, data},
      Module[{selection, tag, cell, original, translation, language},
       tag = data;
       NotebookLocate[tag];
       selection = NotebookSelection[];
       cell = First[Cells[selection]];
       original = First[NotebookRead[cell]];
       language = CurrentValue[cell, {TaggingRules, "language"}];
       SetOptions[cell,
        TaggingRules -> {"original" -> original, "language" -> language}];
       translation =
        TextTranslation[original, "English" -> language,
         Method -> "Google"];
       NotebookWrite[cell, Cell[translation, "Text", Options[cell]]];
       NotebookLocate[tag];
       selection = First[Cells[NotebookSelection[]]];
       attach[selection, tag, "Original", buttonfunction2];
       ]
]

buttonfunction2 = Function[{source, data},
  Module[{selection, tag, cell, language, original},
   tag = data;
   NotebookLocate[tag];
   selection = NotebookSelection[];
   cell = First[Cells[selection]];
   original = CurrentValue[cell, {TaggingRules, "original"}];
   language = CurrentValue[cell, {TaggingRules, "language"}];
   NotebookWrite[cell, Cell[original, "Text", Options[cell]]];
   NotebookLocate[tag];
   selection = First[Cells[NotebookSelection[]]];
   attach[selection, tag, "Translate\n(" <> language <> ")",
    buttonfunction1];
   ]
]

TranslationCell[text_, language_] :=
 Module[{selection, cell, tag},
  tag = First@StringSplit[CreateUUID[], "-"];
  cell = Cell[text, "Text", CellTags -> tag,
    TaggingRules -> {"language" -> language}];
  CellPrint[cell];
  NotebookLocate[tag];
  selection = First[Cells[NotebookSelection[]]];
  attach[selection, tag, "Translate\n(" <> language <> ")",
   buttonfunction1];
  SelectionMove[EvaluationNotebook[], After, Cell];
]

(*
SetOptions[$FrontEnd, InputAliases -> {"rg" -> "»"}];
*)

RasterizeLargeCells[nb_, style_: "Output"] := Module[{},
  NotebookFind[nb, style, All, CellStyle, AutoScroll -> False];
  FrontEndTokenExecute[nb, "SelectionConvert", "BitmapConditional"]
  ]


(*

DocumentWrite[nb_NotebookObject, e_ExpressionCell] := Module[{cell},
  cell = First[ToBoxes[e]];
  NotebookWrite[nb, cell]
]

*)



(*

CreatePalette[
  Column[{
    TextCell["Prototypes", "Title"],
    TextCell["A paclet with useful functions", "SubTitle"],
    TextCell["By: Arnoud Buzing", "Author"]
    }
  ]
]

*)

(* TODO: ArrangeNotebooks[] -- arrange notebooks onscreen in an ordered fashion
SystemInformation["Devices", "ScreenInformation"]
*)
