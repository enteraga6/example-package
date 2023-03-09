#!/usr/bin/env bash

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-verify.common.sh"

# verify_provenance_content verifies provenance content generated by the docker-based generator.
verify_provenance_content() {
    ATTESTATION=$(jq -r '.payload' <"$PROVENANCE" | base64 -d)
    has_assets=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep assets)
    annotated_tags=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep annotated || true)

    echo "  **** Provenance content verification *****"

    # Verify all common provenance fields.
    e2e_verify_common_all "$ATTESTATION"

    e2e_verify_predicate_subject_name "$ATTESTATION" "$BINARY"
    e2e_verify_predicate_builder_id "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_docker-based_slsa3.yml@refs/heads/main"
    e2e_verify_predicate_buildType "$ATTESTATION" "https://github.com/slsa-framework/slsa-github-generator/generic@v1"

    # Ignore tha annotated tags, because they are not part of a release.
    if [[ "$GITHUB_REF_TYPE" == "tag" ]] && [[ -z "$annotated_tags" ]]; then
        assets=$(e2e_get_release_assets_filenames "$GITHUB_REF_NAME")
        if [[ -z "$has_assets" ]]; then
            e2e_assert_eq "$assets" "[\"null\",\"null\"]" "there should be no assets"
        else
            multi_subjects=$(echo "$THIS_FILE" | cut -d '.' -f5 | grep multi-subjects)
            if [[ -n "$multi_subjects" ]]; then
                e2e_assert_eq "$assets" "[\"multiple.intoto.jsonl\",\"null\"]" "there should be assets"
            else
                e2e_assert_eq "$assets" "[\"hello.intoto.jsonl\",\"null\"]" "there should be assets"
            fi
        fi
    fi
}

THIS_FILE=$(e2e_this_file)
BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)
echo "branch is $BRANCH"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is $THIS_FILE"

# Verify provenance authenticity.
SLSA_VERIFIER_EXPERIMENTAL="1"
e2e_run_verifier_all_releases "HEAD"

# Verify the provenance content.
# verify_provenance_content
