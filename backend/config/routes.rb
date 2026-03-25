Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :alerts, only: [:index, :show]

      resources :investigations, only: [:index, :show, :create] do
        member do
          # Narrative gate (Phase 1 → human review)
          post :approve_narrative   # approve → auto-generates SAR → sar_ready
          post :regenerate_narrative # re-run narrative + QA agents
          post :close               # close / monitor (no suspicious activity)

          # SAR gate (Phase 2 → human review)
          post :approve_sar         # final approval
          post :revise_sar          # re-compose SAR, loop back to sar_ready

          # PDF export (sar_approved only)
          get  :export_pdf
        end
      end
    end
  end

  get "/health", to: proc { [200, {}, [{ status: "ok" }.to_json]] }
end
