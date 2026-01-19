  # state.md                                                                                                                                                                                 
                                                                                                                                                                                             
  > **現在地を示す Single Source of Truth**                                                                                                                                                  
  >                                                                                                                                                                                          
  > LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。                                                                                                        
                                                                                                                                                                                             
  ---                                                                                                                                                                                        
                                                                                                                                                                                             
  ## project                                                                                                                                                                                 
                                                                                                                                                                                             
  ```yaml                                                                                                                                                                                    
  active: null                                                                                                                                                                               
  current_milestone: null                                                                                                                                                                    
  status: idle                                                                                                                                                                               
                                                                                                                                                                                             
  ---                                                                                                                                                                                        
  playbook                                                                                                                                                                                   
                                                                                                                                                                                             
  active: play/standalone/build-from-scratch-guide/plan.json
  parent_project: null                                                                                                                                                                       
  current_phase: p1
  branch: feat/validation-enforcement-m1
  last_archived: null                                                                                                                                                                        
  review_pending: false                                                                                                                                                                      
                                                                                                                                                                                             
  ---                                                                                                                                                                                        
  goal                                                                                                                                                                                       
                                                                                                                                                                                             
  self_complete: false                                                                                                                                                                       
  milestone: null                                                                                                                                                                            
  phase: null                                                                                                                                                                                
  done_criteria: []                                                                                                                                                                          
  status: idle                                                                                                                                                                               
                                                                                                                                                                                             
  ---                                                                                                                                                                                        
  session                                                                                                                                                                                    
                                                                                                                                                                                             
  last_start: 2026-01-20 07:55:12
  last_end: 2026-01-20 07:55:11
  last_clear: 2026-01-20                                                                                                                                                                     
                                                                                                                                                                                             
  ---                                                                                                                                                                                        
  config                                                                                                                                                                                     
                                                                                                                                                                                             
  security: admin                                                                                                                                                                            
  toolstack: C                                                                                                                                                                               
  roles:                                                                                                                                                                                     
    orchestrator: claudecode                                                                                                                                                                 
    worker: codex                                                                                                                                                                            
    reviewer: coderabbit                                                                                                                                                                     
    human: user                                                                                                                                                                              
                                                                                                                                                                                             
  ---                                                                                                                                                                                        
  参照                                                                                                                                                                                       
  ┌───────────────────────────────────────┬──────────────────────────────────┐                                                                                                               
  │               ファイル                │               役割               │                                                                                                               
  ├───────────────────────────────────────┼──────────────────────────────────┤                                                                                                               
  │ CLAUDE.md                             │ LLM の振る舞いルール             │                                                                                                               
  ├───────────────────────────────────────┼──────────────────────────────────┤                                                                                                               
  │ docs/repository-map.yaml              │ 全ファイルマッピング（自動生成） │                                                                                                               
  ├───────────────────────────────────────┼──────────────────────────────────┤                                                                                                               
  │ docs/core-feature-reclassification.md │ Hook Unit SSOT                   │                                                                                                               
  ├───────────────────────────────────────┼──────────────────────────────────┤                                                                                                               
  │ ```                                   │                                  │          
