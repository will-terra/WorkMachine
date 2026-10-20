module Sources
  # Plan B: React front end with TypeScript or Next.js.
  class FrontendBr < GithubIssues
    self.key = "frontend_br"
    self.repo = "frontendbr/vagas"

    private
      def relevant?(text) = text.match?(/\breact\b/i) && text.match?(/\b(?:typescript|next\.?js)\b/i)
  end
end
