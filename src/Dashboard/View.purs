module Dashboard.View where

import Dashboard.Model
import Gitlab
import Prelude

import CSS (px, em)
import CSS as CSS
import CSS.TextAlign as CSS
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.JSDate (JSDate)
import Data.Newtype (unwrap)
import Data.String as String
import Data.Time.Duration (Milliseconds(..))
import Halogen.HTML (HTML, ClassName(..))
import Halogen.HTML as H
import Halogen.HTML.CSS (style)
import Halogen.HTML.Properties as P
import Moment (formatMillis, fromNow)

authorImage :: ∀ p i. String -> HTML p i
authorImage url =
  H.img
    [ P.src url
    , P.height 20
    , P.width 20
    , style do
        CSS.borderRadius (20.0 # px) (20.0 # px) (20.0 # px) (20.0 # px)
    ]

-- | TODO: Generate `purescript-fontawesome` library.
data Icon
  = Calendar
  | CircleO
  | ClockO
  | Code
  | CodeFork
  | Stack
  | DotCircleO
  | UserCircleO
  | Refresh
  | QuestionCircleO
  | CheckCircleO
  | TimesCircleO
  | StopCircleO
  | ArrowCircleORight

iconName :: Icon -> String
iconName =
  case _ of
    Calendar          -> "calendar"
    CircleO           -> "circle-o"
    ClockO            -> "clock-o"
    Code              -> "code"
    CodeFork          -> "code-fork"
    Stack             -> "stack"
    DotCircleO        -> "dot-circle-o"
    UserCircleO       -> "user-circle-o"
    Refresh           -> "refresh"
    QuestionCircleO   -> "question-circle-o"
    CheckCircleO      -> "check-circle-o"
    TimesCircleO      -> "times-circle-o"
    StopCircleO       -> "stop-circle-o"
    ArrowCircleORight -> "arrow-circle-o-right"

fontAwesome :: ∀ p i. Icon -> Array ClassName -> HTML p i
fontAwesome icon moreClasses =
  H.i
    [ P.classes (fontAwesomeClasses icon <> moreClasses)
    , style do
         CSS.margin (0.0 # px) (3.0 # px) (0.0 # px) (3.0 # px)
    ]
    [ ]

fontAwesomeClasses :: Icon -> Array ClassName
fontAwesomeClasses icon =
  ClassName <$> [ "fa", "fa-" <> iconName icon ]

statusIcon :: ∀ p i. JobStatus -> HTML p i
statusIcon JobRunning =
  H.span
    [ P.classes (fontAwesomeClasses Stack) ]
    [ fontAwesome CircleO [ ClassName "fa-stack-2x" ]
    , fontAwesome Refresh [ ClassName "fa-stack-1x", ClassName "fa-inverse" ]
    ]
statusIcon status =
  fontAwesome
    case status of
      JobCreated  -> DotCircleO
      JobManual   -> UserCircleO
      JobRunning  -> Refresh
      JobPending  -> QuestionCircleO
      JobSuccess  -> CheckCircleO
      JobFailed   -> TimesCircleO
      JobCanceled -> StopCircleO
      JobSkipped  -> ArrowCircleORight
    (ClassName <$> [ "fa-2x", "align-middle" ])

formatStatus :: ∀ p a. PipelineRow -> HTML p a
formatStatus { id: PipelineId id, status } =
  H.div
    [ style do
        CSS.paddingLeft (2.0 # em)
    ]
    [ H.text $ "#" <> show id
    , H.br []
    , H.text $ show status
    ]


formatCommit :: ∀ p a. CommitRow -> HTML p a
formatCommit { authorImg
             , commitTitle
             , hash: CommitShortHash hash
             , branch: BranchName branch
             } =
  H.div
    [ ]
    [ authorImage authorImg
    , divider
    , fontAwesome CodeFork []
    , H.b_ [ H.text (" " <> branch) ]
    , divider
    , fontAwesome Code []
    , H.text (" " <> hash)
    , H.br_
    , H.div
        [ P.classes [ ClassName "truncate" ] ]
        [ H.text commitTitle ]
    ]
  where
    divider =
      H.span [ style (CSS.marginLeft (1.0 # em)) ] [ ]

formatTimes
  :: ∀ p a. { when     :: JSDate
            , duration :: Milliseconds
            }
  -> HTML p a
formatTimes { when, duration } =
  H.div
    [ style do
        CSS.textAlign CSS.rightTextAlign
        CSS.paddingRight (2.0 # em)
    ]
    [ fontAwesome ClockO []
    , H.text (" " <> formatMillis duration)
    , H.br_
    , fontAwesome Calendar []
    , H.text (" " <> fromNow when)
    ]

rowColor :: PipelineStatus -> ClassName
rowColor =
  case _ of
    Running  -> ClassName "bg-primary"
    Pending  -> ClassName "bg-info"
    Success  -> ClassName "bg-success"
    Failed   -> ClassName "bg-danger"
    Canceled -> ClassName "bg-warning"
    Skipped  -> ClassName "bg-none"

formatPipeline :: ∀ p i. PipelineRow -> HTML p i
formatPipeline pipeline =
    row (cell <$> cells)
  where
   cells =
     [ [ formatStatus pipeline ]
     , [ H.b_ [ H.text $ unwrap pipeline.project.name ] ]
     , [ formatCommit pipeline.commit ]
     , statusIcon <$> pipeline.stages
     , [ formatTimes { when: pipeline.created, duration: pipeline.duration } ]
     ]

   cell :: Array (HTML p i) -> HTML p i
   cell =
     H.td
       [ style do
           CSS.textAlign      CSS.leftTextAlign
           CSS.textWhitespace CSS.whitespaceNoWrap
       ]

   row :: Array (HTML p i) -> HTML p i
   row =
     H.tr
       [ P.classes [ rowColor pipeline.status ] ]
