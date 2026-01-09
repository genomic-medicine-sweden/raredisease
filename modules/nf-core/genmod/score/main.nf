process GENMOD_SCORE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/31/31b331bee43c7ff070bdde5460a4102ba31c3bfb0ee0d70197001ff011036555/data' :
        'community.wave.seqera.io/library/genmod_python:31b2fba4d3b7ba6f' }"

    input:
    tuple val(meta), path(input_vcf), path (fam)
    path (score_config)

    output:
    tuple val(meta), path("*_score.vcf"), emit: vcf
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ''
    def prefix      = task.ext.prefix ?: "${meta.id}"
    def family_file = fam ? "--family_file ${fam}" : ""
    def config_file = score_config ? "--score_config ${score_config}" : ""
    """
    genmod \\
        score \\
        $args \\
        $family_file \\
        $config_file \\
        --outfile ${prefix}_score.vcf \\
        $input_vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genmod: \$(echo \$(genmod --version 2>&1) | sed 's/^.*genmod version: //' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_score.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genmod: \$(echo \$(genmod --version 2>&1) | sed 's/^.*genmod version: //' )
    END_VERSIONS
    """
}
