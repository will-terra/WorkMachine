module Sources
  # Front-end jobs in Brazil, for front-end and full stack profiles. Besides the search terms, it
  # keeps the plan B jobs (two of its terms, such as React with TypeScript).
  class FrontendBr < GithubIssues
    self.key = "frontend_br"
    self.repo = "frontendbr/vagas"

    private
      def relevant?(text) = super || profile.plan_b_relevant?(text)
  end
end
