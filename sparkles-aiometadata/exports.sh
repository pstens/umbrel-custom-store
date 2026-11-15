export APP_SPARKLES_AIOMETADATA_ADMIN_KEY="$(derive_entropy "${app_entropy_identifier}-admin-key")"
export APP_SPARKLES_AIOMETADATA_MOVIELENS_CRED_KEY="$(derive_entropy "${app_entropy_identifier}-movielens-cred-key")"
